class DecisionHubController < ApplicationController
  before_action :authenticate_user!

  def index
    # Page d'index du Decision Hub - toutes les simulations sans seuil minimum
    @simulations = current_user.simulations
                               .order(created_at: :desc)
                               .includes(:property, :project)

    # Si un simulation_id est fourni en paramètre, l'utiliser, sinon prendre la première
    if params[:simulation_id].present?
      @default_simulation = current_user.simulations.find_by(id: params[:simulation_id]) || @simulations.first || current_user.simulations.last
    else
      @default_simulation = @simulations.first || current_user.simulations.last
    end
    @simulation = @default_simulation  # Alias pour les vues partielles

    # Sauvegarder la simulation active en session pour l'IA
    if @default_simulation
      session[:current_simulation_id] = @default_simulation.id
      session[:user_location] = @default_simulation.region
      session[:property_type] = @default_simulation.property&.type_propriete || @default_simulation.property&.type
      session[:total_primes] = @default_simulation.total_simule
    end

    # Générer les données dynamiques pour la simulation par défaut
    if @default_simulation
      begin
        @hub_data = DecisionHub::DataService.new(@default_simulation).generate_dynamic_data
      rescue StandardError => e
        Rails.logger.error "Error generating hub data for simulation #{@default_simulation.id}: #{e.message}"
        @hub_data = generate_empty_hub_data
      end
    else
      @hub_data = generate_empty_hub_data
    end

    # Statistiques rapides — sur toutes les simulations
    @stats = {
      total_simulations: @simulations.count,
      total_potential: @simulations.sum(:total_simule),
      regions: @simulations.unscope(:order).group(:region).count,
      last_activity: @simulations.maximum(:updated_at)
    }
  end

  def load_simulation_data
    # Endpoint AJAX pour charger les données d'une simulation spécifique
    begin
      @simulation = current_user.simulations.find(params[:simulation_id])
      @default_simulation = @simulation  # Alias pour compatibilité avec les vues
      @hub_data = DecisionHub::DataService.new(@simulation).generate_dynamic_data

      # Rendre les sections HTML (les partials utilisent hub_data comme local variable)
      locals = { hub_data: @hub_data }
      sections_html = {
        resume: render_to_string(partial: 'decision_hub/sections/resume', layout: false, locals: locals),
        documents: render_to_string(partial: 'decision_hub/sections/documents', layout: false, locals: locals),
        planning: render_to_string(partial: 'decision_hub/sections/planning', layout: false, locals: locals),
        technical: render_to_string(partial: 'decision_hub/sections/preparation_technique', layout: false, locals: locals)
      }

      render json: {
        success: true,
        data: sections_html,
        simulation: {
          id: @simulation.id,
          title: @simulation.titre || "Simulation #{@simulation.id}",
          region: @simulation.region&.capitalize,
          created_at: @simulation.created_at.strftime("%d/%m/%Y")
        }
      }
    rescue ActiveRecord::RecordNotFound
      render json: { success: false, error: "Simulation introuvable" }, status: :not_found
    rescue StandardError => e
      Rails.logger.error "Error loading simulation data: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { success: false, error: "Erreur lors du chargement des données" }, status: :internal_server_error
    end
  end

  def ai_consultation
    # Endpoint pour les questions IA avec contexte complet
    simulation = current_user.simulations.find(params[:simulation_id])
    question = params[:question]
    conversation_history = params[:conversation_history] || []
    section = params[:section] # Section active si applicable

    # Générer le prompt contextuel
    if section.present?
      prompt = DecisionHub::AiPromptService.build_section_specific_prompt(simulation, section, question)
    else
      prompt = DecisionHub::AiPromptService.build_contextual_prompt(simulation, question, conversation_history)
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
    @hub_data = DecisionHub::MockDataService.new(@simulation).generate_hub_data

    # Préparer le contexte pour la consultation IA
    @ai_context = build_ai_context
  end

  def save_technical_preparation
    # Sauvegarde des données techniques dans simulation.parameters
    begin
      simulation_id   = params[:simulation_id]
      technical_data  = params.require(:technical_preparation).to_unsafe_h

      if simulation_id.present?
        simulation = current_user.simulations.find_by(id: simulation_id)
        if simulation
          existing = simulation.parameters.present? ? JSON.parse(simulation.parameters) : {}
          existing['technical_preparation'] = technical_data
          simulation.update!(parameters: existing.to_json)
        end
      end

      render json: {
        success: true,
        message: "Données techniques sauvegardées avec succès"
      }
    rescue ActionController::ParameterMissing => e
      render json: {
        success: false,
        error: "Paramètres manquants: #{e.message}"
      }, status: :bad_request
    rescue => e
      Rails.logger.error "Erreur lors de la sauvegarde des données techniques: #{e.message}"
      render json: {
        success: false,
        error: "Erreur lors de la sauvegarde: #{e.message}"
      }, status: :internal_server_error
    end
  end

  def expert
    # Charger tous les biens de l'utilisateur — le bien est l'entité centrale
    @properties = current_user.properties
                               .order(updated_at: :desc)
                               .includes(:projects, :simulations)

    # Mode vue d'ensemble : ?all=1 → chat générique sans bien sélectionné
    @overview = params[:all] == '1'

    # Rôle explicite passé en param (multi-rôle : 'entrepreneur' ou 'architect')
    @pro_role = params[:pro_role].presence

    # Pros PM-only (pas de biens propres) → mode chat pro dédié
    if @properties.none? && current_user.professional?
      @is_pro_mode     = true
      @overview        = true  # active la zone de chat dans la vue
      role_filter      = @pro_role  # nil = tous les rôles
      @pro_memberships = current_user.project_members.active.pros
                                     .then { |q| role_filter ? q.where(role: role_filter) : q }
                                     .includes(project: :property)
      @ren0chat_limit  = current_user.ren0chat_monthly_limit
      @ren0chat_used   = Rails.cache.read("ren0chat:#{current_user.id}:#{Date.current.strftime('%Y-%m')}").to_i
      return
    end

    # Sélectionner le bien actif (uniquement si property_id explicite en param)
    # Sans param → @property = nil → affichage de la grille de sélection (sauf si @overview)
    @property = params[:property_id].present? ? current_user.properties.find_by(id: params[:property_id]) : nil

    # Charger le contexte complet du bien sélectionné
    if @property
      @property_projects   = @property.projects.order(updated_at: :desc)
      @property_simulations = @property.simulations.order(created_at: :desc)
      @property_documents  = Document.for_property_and_its_projects(@property).order(created_at: :desc).limit(10)

      # Sauvegarder en session pour l'IA
      session[:current_property_id] = @property.id
      session[:user_location]       = @property.region
      session[:property_type]       = @property.type_propriete_wallonie ||
                                      @property.type_bien_flandre       ||
                                      @property.type_bien_bruxelles      ||
                                      @property.type_propriete
    end

    # Quota Ren0chat pour affichage dans la vue
    @ren0chat_limit = current_user.ren0chat_monthly_limit
    @ren0chat_used  = Rails.cache.read("ren0chat:#{current_user.id}:#{Date.current.strftime('%Y-%m')}").to_i
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
      factures: {
        budget_ok: false,
        delai_ok: true,
        ocr_confidence: 85,
        total_factures: 0,
        completion_rate: 0,
        nb_factures: 0,
        derniere_facture_date: nil
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

  def build_ai_context
    {
      user_region: current_user.region || "wallonie",
      user_type: "particulier",
      property_type: @property&.mapped_type || "maison",
      simulation_total: @hub_data[:total_primes],
      selected_primes: @hub_data[:selected_primes].map { |p| p[:name] }
    }
  end
end
