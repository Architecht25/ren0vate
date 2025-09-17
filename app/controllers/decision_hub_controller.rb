class DecisionHubController < ApplicationController
  before_action :authenticate_user!

  def index
    # Page d'index du Decision Hub - liste des simulations éligibles pour conseil
    @simulations = current_user.simulations
                               .where.not(total_simule: nil)
                               .where('total_simule > ?', 1000) # Seuil minimum pour conseil
                               .order(created_at: :desc)
                               .includes(:property, :project)

    # Prendre la première simulation comme défaut pour l'affichage initial
    @default_simulation = @simulations.first || current_user.simulations.last

    # Générer les données dynamiques pour la simulation par défaut
    if @default_simulation
      @hub_data = DecisionHub::DataService.new(@default_simulation).generate_dynamic_data
    else
      @hub_data = generate_empty_hub_data
    end

    # Statistiques rapides
    base_simulations = current_user.simulations
                                  .where.not(total_simule: nil)
                                  .where('total_simule > ?', 1000)

    @stats = {
      total_simulations: @simulations.count,
      total_potential: base_simulations.sum(:total_simule),
      regions: base_simulations.group(:region).count,
      last_activity: base_simulations.maximum(:updated_at)
    }
  end

  def load_simulation_data
    # Endpoint AJAX pour charger les données d'une simulation spécifique
    simulation = current_user.simulations.find(params[:simulation_id])
    hub_data = DecisionHub::DataService.new(simulation).generate_dynamic_data

    render json: {
      success: true,
      data: hub_data,
      simulation: {
        id: simulation.id,
        title: simulation.titre || "Simulation #{simulation.id}",
        region: simulation.region&.capitalize,
        created_at: simulation.created_at.strftime("%d/%m/%Y")
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "Simulation introuvable" }, status: :not_found
  end

  def ai_consultation
    # Endpoint pour les questions IA avec contexte complet
    simulation = current_user.simulations.find(params[:simulation_id])
    question = params[:question]
    conversation_history = params[:conversation_history] || []
    section = params[:section] # Section active si applicable

    # Générer le prompt contextuel
    if section.present?
      prompt = DecisionHub::AIPromptService.build_section_specific_prompt(simulation, section, question)
    else
      prompt = DecisionHub::AIPromptService.build_contextual_prompt(simulation, question, conversation_history)
    end

    # Pour le moment, retourner une réponse mockée basée sur le contexte
    response = generate_contextual_ai_response(simulation, question, section)

    render json: {
      success: true,
      response: response,
      context_used: true,
      section: section
    }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "Simulation introuvable" }, status: :not_found
  end

  def show
    # Pour le moment, nous utilisons des données mockées pour visualiser l'interface
    # Plus tard, nous intégrerons les vraies données de simulation

    simulation_id = params[:simulation_id] || params[:id]

    # Gérer les cas de démo
    if simulation_id == 'demo'
      # Démo Wallonie
      @simulation = OpenStruct.new(
        id: 'demo',
        titre: 'Démo Wallonie - Rénovation Complète',
        region: 'Wallonie',
        total_simule: 12450,
        created_at: 1.week.ago,
        property: OpenStruct.new(display_name: 'Maison Namur'),
        project: OpenStruct.new(nom: 'Rénovation énergétique complète')
      )
      @property = @simulation.property
    elsif simulation_id == 'demo-bruxelles'
      # Démo Bruxelles
      @simulation = OpenStruct.new(
        id: 'demo-bruxelles',
        titre: 'Démo Bruxelles - Isolation',
        region: 'Bruxelles',
        total_simule: 8750,
        created_at: 3.days.ago,
        property: OpenStruct.new(display_name: 'Appartement Ixelles'),
        project: OpenStruct.new(nom: 'Isolation complète')
      )
      @property = @simulation.property
      # Adapter les données mockées pour Bruxelles
      customize_data_for_bruxelles
    else
      # Simulation réelle
      @simulation = current_user.simulations.find(simulation_id) if simulation_id
      @property = @simulation&.property || current_user.properties.first
    end

    # Données mockées pour démonstration (adaptables selon la région)
    generate_mock_hub_data

    # Préparer le contexte pour la consultation IA
    @ai_context = build_ai_context
  end

  def ai_consultation
    # Endpoint pour les questions IA - pour le moment retourne une réponse mockée
    question = params[:question]
    conversation_history = params[:conversation_history] || []

    # Simulation d'une réponse IA intelligente
    ai_response = generate_mock_ai_response(question)

    render json: {
      success: true,
      response: ai_response,
      timestamp: Time.current.iso8601,
      question: question
    }

  rescue => e
    render json: {
      success: false,
      error: "Erreur lors de la consultation IA: #{e.message}"
    }, status: :internal_server_error
  end

  private

  def generate_empty_hub_data
    # Données par défaut si pas de simulation
    {
      resume: {
        simulation_id: nil,
        total_amount: 0,
        region: "Non défini",
        property_type: "maison",
        primes: [],
        completion_status: { overall: 0 }
      },
      documents: {
        required_documents: [],
        completion_rate: 0,
        completed: [],
        missing: [],
        urgent: []
      },
      planning: {
        timeline: [],
        urgent_deadlines: [],
        total_duration: "Non défini"
      },
      technical: {
        technical_obligations: [],
        compliance_rate: 0,
        critical_issues: [],
        warnings: []
      },
      ai_context: {}
    }
  end

  def generate_contextual_ai_response(simulation, question, section = nil)
    # Charger le contexte complet
    hub_data = DecisionHub::DataService.new(simulation).generate_dynamic_data

    # Générer une réponse mockée intelligente basée sur le contexte réel
    case question.downcase
    when /prochain|suivant|que faire|étape/
      generate_next_action_response(hub_data)
    when /document|papier|dossier/
      generate_documents_response(hub_data)
    when /délai|timing|quand|urgent/
      generate_timing_response(hub_data)
    when /technique|norme|conformité/
      generate_technical_response(hub_data)
    when /optimis|améliorer|maxim/
      generate_optimization_response(hub_data)
    else
      generate_general_response(hub_data, question)
    end
  end

  def generate_next_action_response(hub_data)
    resume = hub_data[:resume]
    documents = hub_data[:documents]
    technical = hub_data[:technical]

    if documents[:urgent].any?
      "🚨 **Action prioritaire**: Vous avez #{documents[:urgent].count} documents URGENTS à obtenir !\n\n" +
      "📋 **À faire MAINTENANT**:\n" +
      documents[:urgent].map { |doc| "• #{doc}" }.join("\n") +
      "\n\n💰 **Impact**: Ces documents bloquent vos #{resume[:total_amount]}€ de primes !"
    elsif technical[:critical_issues].any?
      "⚠️ **Action technique prioritaire**: #{technical[:critical_issues].count} non-conformités critiques détectées !\n\n" +
      "🔧 **À corriger**:\n" +
      technical[:critical_issues].first(3).map { |issue| "• #{issue}" }.join("\n") +
      "\n\n🎯 **Conseil**: Réglez ces points avant de déposer votre dossier."
    else
      "✅ **Excellent !** Votre dossier avance bien (#{documents[:completion_rate]}% documents, #{technical[:compliance_rate]}% conformité).\n\n" +
      "🚀 **Prochaine étape**: Finaliser les derniers détails et préparer le dépôt coordonné de vos primes."
    end
  end

  def generate_documents_response(hub_data)
    documents = hub_data[:documents]
    resume = hub_data[:resume]

    missing_count = documents[:missing].count
    urgent_count = documents[:urgent].count

    response = "📋 **État documents** (#{documents[:completion_rate]}% complétés):\n\n"

    if documents[:completed].any?
      response += "✅ **Déjà collectés**: #{documents[:completed].join(', ')}\n\n"
    end

    if urgent_count > 0
      response += "🚨 **URGENTS** (#{urgent_count}):\n"
      response += documents[:urgent].map { |doc| "• #{doc}" }.join("\n")
      response += "\n\n"
    end

    if missing_count > urgent_count
      remaining = documents[:missing] - documents[:urgent]
      response += "📝 **Restants** (#{remaining.count}):\n"
      response += remaining.first(3).map { |doc| "• #{doc}" }.join("\n")
      response += "\n\n"
    end

    response += "💡 **Conseil**: Commencez par les urgents, ils sont bloquants pour vos #{resume[:total_amount]}€ !"
  end

  def generate_timing_response(hub_data)
    planning = hub_data[:planning]
    resume = hub_data[:resume]

    if planning[:urgent_deadlines].any?
      next_deadline = planning[:urgent_deadlines].first
      days_remaining = (next_deadline[:date] - Date.current).to_i

      "⏰ **Attention délai !**\n\n" +
      "🚨 **Prochaine échéance**: #{next_deadline[:description]}\n" +
      "📅 **Date limite**: #{next_deadline[:date].strftime('%d/%m/%Y')} (dans #{days_remaining} jours)\n" +
      "💰 **Enjeu**: #{next_deadline[:benefit]}\n\n" +
      "🎯 **Action**: #{days_remaining < 30 ? 'URGENT - ' : ''}Préparez votre dossier maintenant !"
    else
      "✅ **Timing optimal** pour vos #{resume[:total_amount]}€ de primes !\n\n" +
      "⏱️ **Durée totale estimée**: #{planning[:total_duration]}\n" +
      "🎯 **Pas d'urgence immédiate**, vous pouvez prendre le temps de bien préparer.\n\n" +
      "💡 **Conseil**: Profitez-en pour optimiser votre dossier et vérifier tous les détails."
    end
  end

  def generate_technical_response(hub_data)
    technical = hub_data[:technical]
    resume = hub_data[:resume]

    critical_count = technical[:critical_issues].count
    warnings_count = technical[:warnings].count

    if critical_count > 0
      "🔧 **Conformité technique** (#{technical[:compliance_rate]}%):\n\n" +
      "❌ **#{critical_count} points CRITIQUES** à corriger:\n" +
      technical[:critical_issues].map { |issue| "• #{issue}" }.join("\n") +
      "\n\n⚠️ **Impact**: Ces non-conformités peuvent faire refuser vos primes !\n" +
      "🎯 **Action**: Corrigez ces points avant le dépôt."
    elsif warnings_count > 0
      "⚠️ **Attention technique** (#{technical[:compliance_rate]}%):\n\n" +
      "🔶 **#{warnings_count} points à vérifier**:\n" +
      technical[:warnings].first(3).map { |warning| "• #{warning}" }.join("\n") +
      "\n\n💡 **Conseil**: Points non bloquants mais recommandés pour optimiser vos #{resume[:total_amount]}€."
    else
      "✅ **Excellente conformité technique !** (#{technical[:compliance_rate]}%)\n\n" +
      "🎯 Votre dossier respecte toutes les normes techniques.\n" +
      "🚀 Vous pouvez passer à la finalisation administrative."
    end
  end

  def generate_optimization_response(hub_data)
    resume = hub_data[:resume]
    primes = resume[:primes]

    current_total = resume[:total_amount]
    high_priority_primes = primes.select { |p| p[:urgency] == "high" || p[:urgency] == "critical" }

    "🚀 **Optimisation de vos #{current_total}€** :\n\n" +
    "💰 **Primes prioritaires** (#{high_priority_primes.count}):\n" +
    high_priority_primes.map { |p| "• #{p[:name]}: #{p[:amount]}€" }.join("\n") +
    "\n\n🎯 **Stratégie recommandée**:\n" +
    "1. **Concentrez-vous sur les primes urgentes** (meilleur ROI)\n" +
    "2. **Déposez en simultané** pour éviter les conflits\n" +
    "3. **Vérifiez les bonus saisonniers** disponibles\n\n" +
    "📈 **Potentiel gain**: +10-15% avec timing optimisé !"
  end

  def generate_general_response(hub_data, question)
    resume = hub_data[:resume]
    overall_completion = resume[:completion_status][:overall]

    "🤖 **Analyse de votre situation** :\n\n" +
    "📊 **Votre projet**: #{resume[:primes].count} primes • #{resume[:total_amount]}€ • #{resume[:region]}\n" +
    "📈 **Avancement global**: #{overall_completion}%\n\n" +
    "🎯 **Mon évaluation**:\n" +
    case overall_completion
    when 0..25
      "🟥 **Début de parcours** - Concentrez-vous sur les documents prioritaires"
    when 26..50
      "🟨 **Bon démarrage** - Continuez sur cette lancée !"
    when 51..75
      "🟦 **Bonne progression** - Plus que quelques détails à régler"
    else
      "🟩 **Excellent !** - Vous êtes prêt pour le dépôt"
    end +
    "\n\n💬 **Questions spécifiques ?** Demandez-moi des détails sur les documents, délais, ou aspects techniques !"
  end

  def customize_data_for_bruxelles
    # Adapter les données pour la démo Bruxelles
    @region_specific = {
      total_primes: 8750,
      prime_names: [
        "Prime Renolution Isolation",
        "Prime Audit PAE",
        "Prime Ventilation Bruxelles"
      ]
    }
  end

  def generate_mock_hub_data
    # Générer les données mockées (adaptées selon la région)
    base_amount = @simulation&.total_simule || 12450
    region = @simulation&.region&.downcase || "wallonie"

    @hub_data = {
      total_primes: base_amount,
      confidence_level: 94,
      selected_primes: generate_mock_primes(region, base_amount),
      obligations: generate_mock_obligations(region),
      recommendations: generate_mock_recommendations(region),
      timeline: generate_mock_timeline(region),
      total_duration: "6-8 semaines",
      preparation_score: 68
    }
  end

  def generate_mock_primes(region, total_amount)
    if region == "bruxelles"
      [
        {
          name: "Prime Renolution Isolation",
          amount: (total_amount * 0.48).round,
          priority: "high",
          timing: "45 jours",
          urgency: "urgent"
        },
        {
          name: "Prime Audit PAE",
          amount: (total_amount * 0.32).round,
          priority: "medium",
          timing: "60 jours",
          urgency: "normal"
        },
        {
          name: "Prime Ventilation Bruxelles",
          amount: (total_amount * 0.20).round,
          priority: "low",
          timing: "Flexible",
          urgency: "flexible"
        }
      ]
    else
      [
        {
          name: "Prime Isolation Toiture",
          amount: (total_amount * 0.34).round,
          priority: "high",
          timing: "30 jours",
          urgency: "urgent"
        },
        {
          name: "Prime Pompe à Chaleur",
          amount: (total_amount * 0.30).round,
          priority: "high",
          timing: "90 jours",
          urgency: "normal"
        },
        {
          name: "Prime Isolation Façade",
          amount: (total_amount * 0.23).round,
          priority: "medium",
          timing: "Printemps",
          urgency: "seasonal"
        },
        {
          name: "Prime Audit Énergétique",
          amount: (total_amount * 0.06).round,
          priority: "low",
          timing: "Flexible",
          urgency: "flexible"
        },
        {
          name: "Prime Ventilation",
          amount: (total_amount * 0.07).round,
          priority: "low",
          timing: "Conditions",
          urgency: "conditional"
        }
      ]
    end
  end

  def generate_mock_obligations(region)
    base_obligations = [
      {
        id: "devis_entrepreneur",
        description: "Obtenir devis détaillé entrepreneur agréé",
        deadline: "Avant dépôt",
        completed: false,
        type: "administrative",
        importance: "critical"
      },
      {
        id: "photos_avant",
        description: "Photos avant travaux horodatées",
        deadline: "Avant commencement",
        completed: false,
        type: "administrative",
        importance: "high"
      }
    ]

    # Obligations techniques spécifiques à l'isolation
    technical_obligations = [
      {
        id: "resistance_thermique_toiture",
        description: "Résistance thermique R ≥ 6,0 m²K/W pour isolation toiture",
        deadline: "Specification technique",
        completed: false,
        type: "technical",
        importance: "critical",
        details: "Minimum requis pour prime isolation toiture. Vérifier marquage CE des matériaux."
      },
      {
        id: "resistance_thermique_mur",
        description: "Résistance thermique R ≥ 3,5 m²K/W pour isolation façade",
        deadline: "Specification technique",
        completed: false,
        type: "technical",
        importance: "critical",
        details: "Épaisseur minimum selon type d'isolant. Tenir compte des ponts thermiques."
      },
      {
        id: "ventilation_chassis",
        description: "Grilles de ventilation obligatoires pour châssis étanches",
        deadline: "Installation châssis",
        completed: false,
        type: "technical",
        importance: "high",
        details: "Débit minimum 30 m³/h par grille. Positionnement selon normes NBN."
      },
      {
        id: "pare_vapeur",
        description: "Pose pare-vapeur côté chaud pour isolation intérieure",
        deadline: "Avant isolation",
        completed: false,
        type: "technical",
        importance: "high",
        details: "Éviter condensation interstitielle. Étanchéité aux raccords obligatoire."
      },
      {
        id: "pont_thermique",
        description: "Traitement ponts thermiques Ψ ≤ 0,15 W/mK",
        deadline: "Conception travaux",
        completed: false,
        type: "technical",
        importance: "medium",
        details: "Continuité isolation aux jonctions. Calculs thermiques si requis."
      }
    ]

    if region == "bruxelles"
      base_obligations += [
        {
          id: "declaration_urbanisme",
          description: "Déclaration préalable urbanisme",
          deadline: "20 jours ouvrables",
          completed: false,
          type: "administrative",
          importance: "critical"
        },
        {
          id: "audit_pae",
          description: "Audit PAE par conseiller agréé",
          deadline: "Avant travaux",
          completed: false,
          type: "administrative",
          importance: "high"
        },
        {
          id: "ventilation_bruxelles",
          description: "Système ventilation double flux pour rénovation lourde",
          deadline: "Si PEB < C",
          completed: false,
          type: "technical",
          importance: "high",
          details: "Rendement ≥ 85%. Débit selon surface plancher."
        }
      ]
    else
      base_obligations += [
        {
          id: "certificat_peb",
          description: "Certificat PEB valide (< 10 ans)",
          deadline: "Requis maintenant",
          completed: false,
          type: "administrative",
          importance: "critical"
        },
        {
          id: "declaration_commune",
          description: "Déclaration préalable commune",
          deadline: "15 jours ouvrables",
          completed: false,
          type: "administrative",
          importance: "medium"
        },
        {
          id: "ventilation_wallonie",
          description: "Aération permanente 3,6 m³/h par m² habitable",
          deadline: "Post-isolation",
          completed: false,
          type: "technical",
          importance: "high",
          details: "Grilles autoréglables ou hygroréglables. Évacuation humidité."
        }
      ]
    end

    (base_obligations + technical_obligations).shuffle
  end

  def generate_mock_recommendations(region)
    # Recommandations sur les matériaux durables (communes)
    sustainable_materials = [
      {
        type: "materials",
        description: "Privilégier isolants biosourcés (ouate cellulose, fibre bois)",
        impact: "medium",
        benefit: "Écologique + respirant",
        icon: "🌱",
        details: "Meilleur déphasage thermique, régulation hygrométrique naturelle"
      },
      {
        type: "materials",
        description: "Éviter polystyrène en facade (risque incendie)",
        impact: "high",
        benefit: "Sécurité + durabilité",
        icon: "🔥",
        details: "Préférer laine de roche, fibre bois ou polyuréthane"
      },
      {
        type: "materials",
        description: "Châssis bois-alu ou PVC recyclé certifié",
        impact: "medium",
        benefit: "Longévité + écologie",
        icon: "♻️",
        details: "Meilleure isolation + maintenance réduite"
      },
      {
        type: "technical",
        description: "Ventilation double flux avec récupération chaleur",
        impact: "high",
        benefit: "Économies 30-40%",
        icon: "💨",
        details: "Rendement mini 85%, filtration air neuf"
      },
      {
        type: "quality",
        description: "Certification Passivhaus ou équivalent",
        impact: "medium",
        benefit: "Performance garantie",
        icon: "⭐",
        details: "Standards les plus exigeants, suivi qualité"
      }
    ]

    if region == "bruxelles"
      region_specific = [
        {
          type: "timing",
          description: "Déposer avant fin d'année fiscale",
          impact: "high",
          benefit: "+10% bonus annuel",
          icon: "⏰"
        },
        {
          type: "audit",
          description: "Audit PAE obligatoire en premier",
          impact: "high",
          benefit: "Prérequis légal",
          icon: "📋"
        },
        {
          type: "entrepreneur",
          description: "Entrepreneur agréé Bruxelles Environnement",
          impact: "medium",
          benefit: "Garantie éligibilité",
          icon: "🏗️"
        },
        {
          type: "materials",
          description: "Isolants avec lambda ≤ 0,04 W/mK pour Renolution",
          impact: "high",
          benefit: "Éligibilité prime",
          icon: "🎯",
          details: "Laine de verre haute performance, polyuréthane, fibre bois"
        }
      ]
    else
      region_specific = [
        {
          type: "timing",
          description: "Déposer prime isolation avant fin octobre",
          impact: "high",
          benefit: "+15% de bonus hivernal",
          icon: "⏰"
        },
        {
          type: "combination",
          description: "Combiner pompe à chaleur + isolation",
          impact: "medium",
          benefit: "+800€ de majoration",
          icon: "🔗"
        },
        {
          type: "entrepreneur",
          description: "Choisir entrepreneur certifié RGE",
          impact: "medium",
          benefit: "Garantie éligibilité",
          icon: "🏗️"
        },
        {
          type: "audit",
          description: "Effectuer audit énergétique complet",
          impact: "low",
          benefit: "Optimisation globale",
          icon: "📊"
        },
        {
          type: "materials",
          description: "Isolants naturels bonus +5% en Wallonie",
          impact: "medium",
          benefit: "Prime majorée",
          icon: "🌿",
          details: "Chanvre, lin, ouate cellulose, liège expansé"
        }
      ]
    end

    (region_specific + sustainable_materials.sample(3)).shuffle
  end

  def generate_mock_timeline(region)
    [
      {
        name: "Préparation Dossier",
        duration: "2-3 semaines",
        status: "active",
        actions: [
          {
            description: "Rassembler documents techniques",
            type: "documents",
            button_text: "Voir la liste"
          },
          {
            description: "Valider éligibilité entrepreneur",
            type: "entrepreneur",
            button_text: "Trouver entrepreneurs"
          },
          {
            description: "Obtenir devis conformes",
            type: "quotes",
            button_text: "Modèles devis"
          }
        ]
      },
      {
        name: "Dépôt Coordonné",
        duration: "1 semaine",
        status: "pending",
        actions: [
          {
            description: "Dépôt simultané primes compatibles",
            type: "submission",
            button_text: "Préparer formulaires"
          },
          {
            description: "Validation dossiers complets",
            type: "validation",
            button_text: "Check-list finale"
          }
        ]
      },
      {
        name: "Suivi & Travaux",
        duration: "3-6 mois",
        status: "future",
        actions: [
          {
            description: "Suivi administratif automatisé",
            type: "monitoring",
            button_text: "Activer suivi"
          },
          {
            description: "Coordination travaux",
            type: "coordination",
            button_text: "Planning chantier"
          }
        ]
      }
    ]
  end

  def build_ai_context
    {
      user_region: current_user.region || "wallonie",
      user_type: "particulier",
      property_type: map_property_type(@property) || "maison",
      simulation_total: @hub_data[:total_primes],
      selected_primes: @hub_data[:selected_primes].map { |p| p[:name] }
    }
  end

  # Méthode helper pour mapper le type de propriété selon la région
  def map_property_type(property)
    return "maison" unless property

    case property.region&.downcase
    when 'flandre'
      property.type_bien_flandre || "maison"
    when 'wallonie'
      property.type_propriete_wallonie || "maison"
    when 'bruxelles'
      property.type_bien_bruxelles || property.type || "maison"
    else
      property.type || "maison"
    end
  end

  def generate_mock_ai_response(question)
    # Réponses mockées basées sur les mots-clés de la question
    case question.downcase
    when /optimis|combinai|maxim/
      "Excellente question ! Pour optimiser vos primes, je recommande de commencer par la prime isolation toiture (4,200€) car elle a un délai court. Ensuite, vous pourrez combiner avec la pompe à chaleur pour obtenir une majoration de 15%. Cela porterait votre total à environ 13,250€. Les primes isolation + pompe à chaleur sont parfaitement compatibles en Wallonie."

    when /timing|délai|quand|moment/
      "Le timing optimal pour votre projet serait : \n\n1️⃣ **Octobre 2024** : Dépôt prime isolation toiture (bonus hivernal 15%)\n2️⃣ **Novembre 2024** : Prime pompe à chaleur \n3️⃣ **Printemps 2025** : Prime façade (conditions météo optimales)\n\nCette séquence maximise vos aides et respecte les contraintes saisonnières."

    when /document|papier|dossier/
      "Voici les documents essentiels pour vos primes :\n\n📋 **Obligatoires** :\n• Certificat PEB valide (< 10 ans)\n• Devis détaillés entrepreneurs agréés RGE\n• Photos avant travaux horodatées\n• Déclaration préalable commune\n\n📋 **Recommandés** :\n• Relevé cadastral\n• Preuves de revenus\n• Plans techniques détaillés\n\nVoulez-vous que je vous guide pour obtenir un document spécifique ?"

    when /entrepreneur|artisan|rge/
      "Pour vos primes (12,450€), vous DEVEZ choisir des entrepreneurs agréés RGE. C'est obligatoire !\n\n🏗️ **Critères essentiels** :\n• Certification RGE valide\n• Assurance décennale\n• Références vérifiables\n• Devis conformes aux normes\n\nJe peux vous recommander des entrepreneurs certifiés dans votre région. Dans quelle commune êtes-vous situé ?"

    when /prix|coût|budget/
      "Votre budget primes de 12,450€ est excellent ! Voici la répartition optimisée :\n\n💰 **Primes prioritaires** :\n• Isolation toiture : 4,200€ (ROI rapide)\n• Pompe à chaleur : 3,800€ (économies long terme)\n\n💰 **Primes complémentaires** :\n• Isolation façade : 2,850€ \n• Audit + Ventilation : 1,600€\n\nAvec les majorations possibles, vous pourriez atteindre 13,500€ !"

    else
      "Je comprends votre question sur #{extract_topic(question)}. Basé sur vos simulations de 12,450€ en Wallonie, je peux vous donner des conseils précis.\n\n🤖 **Mon analyse** :\n• 5 primes compatibles identifiées\n• Potentiel d'optimisation : +8%\n• Timeline recommandée : 6-8 semaines\n\nPouvez-vous me dire quel aspect vous préoccupe le plus :\n🔹 Les délais et timing\n🔹 Les documents requis  \n🔹 L'optimisation des montants\n🔹 Le choix des entrepreneurs ?"
    end
  end

  def extract_topic(question)
    # Simple extraction de sujet basée sur des mots-clés
    topics = {
      /prime|aide|subvention/ => "les primes énergétiques",
      /travaux|rénovation|isolation/ => "vos travaux de rénovation",
      /délai|temps|timing/ => "les délais et timing",
      /entrepreneur|artisan/ => "le choix d'entrepreneurs",
      /document|papier|dossier/ => "les documents administratifs"
    }

    topic = topics.find { |pattern, _| question.match?(pattern) }
    topic ? topic[1] : "votre projet de rénovation"
  end
end
