# Service pour générer les données mockées du Decision Hub (mode démo, sans simulation réelle)
class DecisionHub::MockDataService
  def initialize(simulation)
    @simulation = simulation
  end

  def generate_hub_data
    base_amount = @simulation&.total_simule || 12450
    region = @simulation&.region&.downcase || "wallonie"

    {
      total_primes: base_amount,
      confidence_level: 94,
      selected_primes: generate_primes(region, base_amount),
      obligations: generate_obligations(region),
      recommendations: generate_recommendations(region),
      timeline: generate_timeline(region),
      total_duration: calculate_dynamic_deadline_duration,
      preparation_score: 68
    }
  end

  private

  def generate_primes(region, total_amount)
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

  def generate_obligations(region)
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

  def generate_recommendations(region)
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
          description: "Choisir entrepreneur certifié agréé",
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

  def generate_timeline(region)
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

  def calculate_dynamic_deadline_duration
    return "Non défini" unless @simulation

    region = @simulation.region&.downcase
    project = @simulation.project
    property = @simulation.property

    deadlines = []

    case region
    when 'flandre'
      # Date limite suppression prime PEB Flandre
      deadline_peb_suppression = Date.new(2026, 6, 30)
      deadlines << deadline_peb_suppression

      # Délai facture d'acompte (2 ans)
      if project&.date_début.present?
        deadline_acompte = project.date_début + 2.years
        deadlines << deadline_acompte
      end

      # Délai certificat PEB (5 ans)
      if property&.date_peb_avant_travaux.present?
        deadline_peb = property.date_peb_avant_travaux + 5.years
        deadlines << deadline_peb
      end

    when 'wallonie'
      # Date limite arrêt des aides Wallonie
      deadline_wallonie_arret = Date.new(2026, 9, 30)
      deadlines << deadline_wallonie_arret

      # Délai facture de solde (8 mois)
      if project&.date_fin.present?
        deadline_solde = project.date_fin + 8.months
        deadlines << deadline_solde
      end

      # Délai prime audit (4 mois)
      if project&.date_audit.present?
        deadline_audit = project.date_audit + 4.months
        deadlines << deadline_audit
      end

    when 'bruxelles'
      # Délai facture de solde (12 mois)
      if project&.date_fin.present?
        deadline_brux = project.date_fin + 12.months
        deadlines << deadline_brux
      end
    end

    return "Non défini" if deadlines.empty?

    earliest_deadline = deadlines.min
    days_remaining = (earliest_deadline - Date.current).to_i

    if days_remaining <= 0
      "⚠️ Délai dépassé"
    elsif days_remaining <= 30
      "#{days_remaining} jour#{days_remaining > 1 ? 's' : ''}"
    elsif days_remaining <= 90
      weeks_remaining = (days_remaining / 7.0).ceil
      "#{weeks_remaining} semaine#{weeks_remaining > 1 ? 's' : ''}"
    elsif days_remaining <= 365
      months_remaining = (days_remaining / 30.0).ceil
      "#{months_remaining} mois"
    else
      years_remaining = (days_remaining / 365.0).round(1)
      "#{years_remaining} an#{years_remaining > 1 ? 's' : ''}"
    end
  end
end
