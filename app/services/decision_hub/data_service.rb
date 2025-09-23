# Service principal pour orchestrer toutes les données du Decision Hub
class DecisionHub::DataService
  def initialize(simulation)
    @simulation = simulation

    # Validation de la simulation
    unless @simulation
      raise ArgumentError, "Simulation ne peut pas être nil"
    end

    @region = simulation&.region&.downcase || "wallonie"
    @selected_primes = []

    begin
      @selected_primes = extract_selected_primes
    rescue StandardError => e
      Rails.logger.error "Error extracting primes in DataService: #{e.message}"
      @selected_primes = extract_mock_primes_by_region
    end
  end

  def generate_dynamic_data
    begin
      data = {
        resume: generate_resume_data,
        documents: safe_call_service { DecisionHub::DocumentRequirementsService.for_simulation(@simulation) },
        planning: safe_call_service { DecisionHub::PlanningService.for_simulation(@simulation) },
        technical: safe_call_service { DecisionHub::TechnicalRequirementsService.for_simulation(@simulation) },
        factures: generate_factures_data,
        ai_context: build_ai_context
      }

      # Ajouter les données d'exemplarité pour les entreprises bruxelloises
      if is_bruxelles_entreprise?
        data[:exemplarite] = safe_call_service { DecisionHub::ExemplariteCalculatorService.new(@simulation).calculate_exemplarite_potential }
      end

      data
    rescue StandardError => e
      Rails.logger.error "Error generating dynamic data: #{e.message}"
      generate_fallback_data
    end
  end

  private

  def extract_category_from_slug(slug)
    # Extraire la catégorie depuis le slug de la prime
    case slug
    when /isolation|toiture|mur|sol/i then "isolation"
    when /chauffage|pompe|chaudiere/i then "chauffage"
    when /ventilation|vmc/i then "ventilation"
    when /menuiserie|chassis|fenetre/i then "menuiserie"
    when /audit|pae/i then "audit"
    when /eclairage|led/i then "eclairage"
    else "autre"
    end
  end

  def determine_prime_status(prime)
    # Déterminer le statut basé sur les données de la prime
    return "conditional" if prime["conditions"].present?
    return "eligible" if prime["calculated_amount"].to_f > 0
    "pending"
  end

  def determine_prime_urgency(prime)
    # Déterminer l'urgence basée sur le type de prime
    category = extract_category_from_slug(prime["slug"])
    case category
    when "audit" then "critical"
    when "isolation", "chauffage" then "high"
    when "ventilation" then "medium"
    else "low"
    end
  end

  def build_prime_details(prime)
    # Construire une description détaillée de la prime
    details = []
    details << "#{prime['user_input_value']} #{prime['unite']}" if prime['user_input_value'].present?
    details << prime['conseil'] if prime['conseil'].present?
    details.join(" • ")
  end

  def generate_resume_data
    {
      simulation_id: @simulation.id,
      total_amount: @simulation.total_simule || calculate_mock_total,
      region: @region.capitalize,
      property_type: extract_property_type,
      primes: @selected_primes,
      completion_status: calculate_completion_status
    }
  end

  def extract_selected_primes
    # Récupérer les vraies primes de la simulation depuis les paramètres JSON
    if @simulation&.parameters.present?
      begin
        params_data = JSON.parse(@simulation.parameters)
        primes = extract_primes_from_simulation_data(params_data)
        return primes if primes.any?
      rescue JSON::ParserError, StandardError => e
        Rails.logger.warn "Failed to parse simulation parameters for Decision Hub: #{e.message}"
      end
    end

    # Fallback vers les données mock basées sur la région
    extract_mock_primes_by_region
  end

  def extract_primes_from_simulation_data(params_data)
    selected_primes = []

    if params_data["prime_cards"].present?
      params_data["prime_cards"].each do |category_key, category_data|
        next unless category_data["primes"].present?

        category_data["primes"].each do |prime|
          # Prendre seulement les primes avec montant > 0
          amount = (prime["calculated_amount"] || prime["amount"] || 0).to_f

          if amount > 0
            selected_primes << {
              name: prime["titre"] || prime["name"],
              amount: amount.round(0),
              category: prime["category"] || extract_category_from_slug(prime["slug"]),
              slug: prime["slug"],
              status: determine_prime_status(prime),
              urgency: determine_prime_urgency(prime),
              user_input: prime["user_input_value"] || 0,
              details: prime["description"] || build_prime_details(prime)
            }
          end
        end
      end
    end

    # Si aucune prime trouvée, utiliser le fallback
    selected_primes.empty? ? extract_mock_primes_by_region : selected_primes
  end

  def extract_mock_primes_by_region
    if @region == "bruxelles"
      [
        {
          name: "Prime Renolution Isolation",
          amount: 4200,
          category: "isolation",
          status: "eligible",
          urgency: "high"
        },
        {
          name: "Prime Audit PAE",
          amount: 800,
          category: "audit",
          status: "eligible",
          urgency: "critical"
        },
        {
          name: "Prime Ventilation Bruxelles",
          amount: 1500,
          category: "ventilation",
          status: "conditional",
          urgency: "medium"
        }
      ]
    else
      [
        {
          name: "Isolation toiture",
          amount: 4500,
          category: "isolation",
          status: "eligible",
          urgency: "high"
        },
        {
          name: "Pompe à chaleur",
          amount: 3200,
          category: "chauffage",
          status: "eligible",
          urgency: "medium"
        },
        {
          name: "Châssis performants",
          amount: 2750,
          category: "menuiserie",
          status: "eligible",
          urgency: "low"
        }
      ]
    end
  end

  def calculate_mock_total
    @selected_primes.sum { |prime| prime[:amount] }
  end

  def extract_property_type
    return "maison" unless @simulation&.property

    begin
      case @region
      when 'flandre'
        @simulation.property.type_bien_flandre || "maison"
      when 'wallonie'
        @simulation.property.type_propriete_wallonie || "maison"
      when 'bruxelles'
        @simulation.property.type_bien_bruxelles || @simulation.property.type || "maison"
      else
        @simulation.property.type || "maison"
      end
    rescue StandardError => e
      Rails.logger.warn "Error extracting property type: #{e.message}"
      "maison"
    end
  end

  def calculate_completion_status
    {
      documents: 30, # % de completion
      planning: 0,
      technical: 25,
      overall: 18
    }
  end

  def build_ai_context
    # Contexte basique pour l'IA
    {
      simulation_id: @simulation.id,
      region: @simulation.region,
      prime_count: @simulation.prime_ids&.count || 0,
      status: "ready_for_consultation"
    }
  end

  def identify_critical_issues
    issues = []
    issues << "Documents manquants" if calculate_completion_status[:documents] < 50
    issues << "Délais critiques" if has_urgent_deadlines?
    issues << "Non-conformité technique" if calculate_completion_status[:technical] < 50
    issues
  end

  def identify_next_actions
    actions = []
    actions << "Rassembler documents RGE" if calculate_completion_status[:documents] < 50
    actions << "Vérifier résistance thermique" if calculate_completion_status[:technical] < 50
    actions << "Planifier dépôt dossier" if calculate_completion_status[:planning] < 25
    actions
  end

  def has_urgent_deadlines?
    # Logique pour détecter les délais urgents
    @selected_primes.any? { |prime| prime[:urgency] == "critical" || prime[:urgency] == "high" }
  end

  def generate_factures_data
    # Récupérer les factures liées à la simulation via le projet
    project = @simulation.project

    if project
      factures = project.factures
      total_factures = factures.sum(:montant) || 0
      budget_simulation = @simulation.total_simule || 0

      # Vérification délai 12 mois
      derniere_facture = factures.order(:date_facture).last
      delai_ok = if derniere_facture
                   (Date.current - derniere_facture.date_facture) <= 365.days
                 else
                   true # Pas de facture = délai OK
                 end

      # Calcul confiance OCR moyenne
      ocr_confidence = if factures.any?
                         factures.average(:confiance_ocr)&.round || 85
                       else
                         85
                       end

      {
        budget_ok: total_factures <= budget_simulation * 1.1, # Tolérance 10%
        delai_ok: delai_ok,
        ocr_confidence: ocr_confidence,
        total_factures: total_factures,
        completion_rate: factures.any? ? 100 : 0,
        nb_factures: factures.count,
        derniere_facture_date: derniere_facture&.date_facture
      }
    else
      # Pas de projet = données par défaut
      {
        budget_ok: true,
        delai_ok: true,
        ocr_confidence: 85,
        total_factures: 0,
        completion_rate: 0,
        nb_factures: 0,
        derniere_facture_date: nil
      }
    end
  end

  def is_bruxelles_entreprise?
    @region == 'bruxelles' && @simulation&.property&.is_entreprise?
  end

  # Méthodes de sécurité pour éviter les erreurs 500
  def safe_call_service
    yield
  rescue StandardError => e
    Rails.logger.error "Service call failed: #{e.message}"
    default_service_response
  end

  def default_service_response
    {
      status: "error",
      message: "Service temporairement indisponible",
      required_documents: [],
      key_documents: [],
      completion_rate: 0,
      completed: [],
      missing: [],
      urgent: [],
      by_category: {},
      critical_steps: [],
      timeline: [],
      urgent_deadlines: [],
      total_duration: "Non défini",
      technical_obligations: [],
      compliance_rate: 0,
      critical_issues: [],
      warnings: []
    }
  end

  def generate_fallback_data
    {
      resume: {
        simulation_id: @simulation&.id,
        total_amount: @simulation&.total_simule || 0,
        region: @region.capitalize,
        property_type: "maison",
        primes: [],
        completion_status: { overall: 0 }
      },
      documents: default_service_response,
      planning: default_service_response,
      technical: default_service_response,
      factures: {
        budget_ok: true,
        delai_ok: true,
        ocr_confidence: 0,
        total_factures: 0,
        completion_rate: 0,
        nb_factures: 0,
        derniere_facture_date: nil
      },
      ai_context: "Données temporairement indisponibles"
    }
  end

  def build_ai_context
    begin
      "Simulation #{@simulation&.id} en #{@region.capitalize} - #{@selected_primes.count} primes sélectionnées"
    rescue StandardError
      "Contexte non disponible"
    end
  end
end
