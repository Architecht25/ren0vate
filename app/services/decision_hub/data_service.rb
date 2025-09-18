# Service principal pour orchestrer toutes les données du Decision Hub
class DecisionHub::DataService
  def initialize(simulation)
    @simulation = simulation
    @region = simulation.region&.downcase || "wallonie"
    @selected_primes = extract_selected_primes
  end

  def generate_dynamic_data
    {
      resume: generate_resume_data,
      documents: DecisionHub::DocumentRequirementsService.for_simulation(@simulation),
      planning: DecisionHub::PlanningService.for_simulation(@simulation),
      technical: DecisionHub::TechnicalRequirementsService.for_simulation(@simulation),
      factures: generate_factures_data,
      ai_context: build_ai_context
    }
  end

  private

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
    # Pour le moment, on utilise des données mock basées sur la région
    # Plus tard, on intégrera les vraies primes sélectionnées
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
    return "maison" unless @simulation.property

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
end
