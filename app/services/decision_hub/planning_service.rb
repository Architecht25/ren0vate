# Service pour générer le planning et les échéances selon les primes sélectionnées
class DecisionHub::PlanningService
  def self.for_simulation(simulation)
    new(simulation).generate_planning
  end

  def initialize(simulation)
    @simulation = simulation
    @region = simulation.region&.downcase || "wallonie"
    @selected_primes = extract_selected_primes(simulation)
  end

  def generate_planning
    {
      timeline: get_timeline_phases,
      urgent_deadlines: get_urgent_deadlines,
      optimal_timing: get_optimal_timing,
      seasonal_constraints: get_seasonal_constraints,
      total_duration: calculate_total_duration,
      critical_path: identify_critical_path,
      critical_steps: get_critical_steps,
      next_deadline: get_next_deadline
    }
  end

  private

  def get_timeline_phases
    phases = [
      {
        name: "Préparation dossier",
        duration: "2-3 semaines",
        status: determine_phase_status("preparation"),
        start_date: Date.current,
        end_date: Date.current + 3.weeks,
        actions: get_preparation_actions,
        dependencies: []
      },
      {
        name: "Dépôt coordonné",
        duration: "1 semaine",
        status: "pending",
        start_date: Date.current + 3.weeks,
        end_date: Date.current + 4.weeks,
        actions: get_submission_actions,
        dependencies: ["preparation"]
      },
      {
        name: "Réponse administrative",
        duration: get_admin_response_duration,
        status: "future",
        start_date: Date.current + 4.weeks,
        end_date: Date.current + 4.weeks + get_admin_response_weeks.weeks,
        actions: get_admin_response_actions,
        dependencies: ["submission"]
      },
      {
        name: "Réalisation travaux",
        duration: "2-6 mois",
        status: "future",
        start_date: Date.current + 4.weeks + get_admin_response_weeks.weeks,
        end_date: Date.current + 4.weeks + get_admin_response_weeks.weeks + 6.months,
        actions: get_work_actions,
        dependencies: ["admin_response"]
      }
    ]

    add_seasonal_adjustments(phases)
  end

  def get_urgent_deadlines
    deadlines = []

    # Délais spécifiques par région
    case @region
    when "bruxelles"
      if has_renolution_prime?
        deadlines << {
          description: "Dépôt prime Renolution avant fin année fiscale",
          date: Date.new(Date.current.year, 12, 31),
          urgency: "high",
          benefit: "+10% bonus annuel"
        }
      end
    else
      if has_isolation_prime?
        # Bonus hivernal Wallonie
        deadline_date = Date.new(Date.current.year, 10, 31)
        if Date.current <= deadline_date
          deadlines << {
            description: "Dépôt prime isolation avant fin octobre",
            date: deadline_date,
            urgency: "high",
            benefit: "+15% bonus hivernal"
          }
        end
      end
    end

    # Délais saisonniers généraux
    if has_exterior_work?
      spring_start = Date.new(Date.current.year, 3, 1)
      if Date.current < spring_start
        deadlines << {
          description: "Attendre conditions météo favorables",
          date: spring_start,
          urgency: "medium",
          benefit: "Conditions optimales travaux"
        }
      end
    end

    deadlines.sort_by { |d| d[:date] }
  end

  def get_optimal_timing
    recommendations = []

    # Timing optimal par prime
    @selected_primes.each do |prime|
      case prime[:category]
      when "isolation"
        recommendations << {
          prime: prime[:name],
          optimal_period: "Octobre-Novembre",
          reason: "Bonus hivernal + conditions météo",
          priority: "high"
        }
      when "chauffage"
        recommendations << {
          prime: prime[:name],
          optimal_period: "Automne-Hiver",
          reason: "Installation avant période froide",
          priority: "medium"
        }
      when "menuiserie"
        recommendations << {
          prime: prime[:name],
          optimal_period: "Printemps-Été",
          reason: "Conditions météo favorables",
          priority: "low"
        }
      end
    end

    recommendations
  end

  def get_seasonal_constraints
    constraints = []

    if has_exterior_work?
      constraints << {
        type: "weather",
        description: "Travaux extérieurs selon météo",
        optimal_months: ["Mars", "Avril", "Mai", "Juin", "Septembre", "Octobre"],
        avoid_months: ["Décembre", "Janvier", "Février"]
      }
    end

    if @region == "wallonie" && has_isolation_prime?
      constraints << {
        type: "bonus",
        description: "Bonus hivernal isolation Wallonie",
        optimal_months: ["Octobre", "Novembre"],
        benefit: "+15%"
      }
    end

    constraints
  end

  def calculate_total_duration
    base_duration = 16 # semaines de base

    # Ajustements selon complexité
    complexity_factor = @selected_primes.count * 2
    weather_factor = has_exterior_work? ? 4 : 0
    admin_factor = @region == "bruxelles" ? 2 : 0

    total_weeks = base_duration + complexity_factor + weather_factor + admin_factor

    "#{total_weeks}-#{total_weeks + 4} semaines"
  end

  def identify_critical_path
    critical_actions = []

    # Actions bloquantes identifiées
    critical_actions << "Obtenir devis entrepreneur agréé" if missing_rge_quote?
    critical_actions << "Audit PAE obligatoire" if @region == "bruxelles" && missing_audit?
    critical_actions << "Déclaration urbanisme" if needs_urban_declaration?

    critical_actions
  end

  # Actions par phase
  def get_preparation_actions
    actions = [
      {
        description: "Rassembler documents administratifs",
        duration: "3-5 jours",
        responsible: "Demandeur",
        status: "pending"
      },
      {
        description: "Obtenir devis entrepreneurs agréés",
        duration: "1-2 semaines",
        responsible: "Entrepreneurs",
        status: "pending"
      }
    ]

    if @region == "bruxelles"
      actions << {
        description: "Programmer audit PAE",
        duration: "1 semaine",
        responsible: "Conseiller agréé",
        status: "critical"
      }
    end

    actions
  end

  def get_submission_actions
    [
      {
        description: "Dépôt simultané primes compatibles",
        duration: "1-2 jours",
        responsible: "Demandeur",
        status: "pending"
      },
      {
        description: "Validation dossiers complets",
        duration: "2-3 jours",
        responsible: "Administration",
        status: "pending"
      }
    ]
  end

  def get_admin_response_actions
    duration = get_admin_response_duration
    [
      {
        description: "Instruction dossier",
        duration: duration,
        responsible: "Administration régionale",
        status: "future"
      },
      {
        description: "Notification décision",
        duration: "2-3 jours",
        responsible: "Administration",
        status: "future"
      }
    ]
  end

  def get_work_actions
    [
      {
        description: "Commande matériaux",
        duration: "1-2 semaines",
        responsible: "Entrepreneur",
        status: "future"
      },
      {
        description: "Réalisation travaux",
        duration: "Variable selon ampleur",
        responsible: "Entrepreneur",
        status: "future"
      },
      {
        description: "Contrôle final",
        duration: "1 jour",
        responsible: "Demandeur",
        status: "future"
      }
    ]
  end

  # Helpers
  def extract_selected_primes(simulation)
    DecisionHub::DataService.new(simulation).send(:extract_selected_primes)
  end

  def determine_phase_status(phase)
    case phase
    when "preparation"
      # Vérifier si documents collectés
      completion = DecisionHub::DocumentRequirementsService.for_simulation(@simulation)[:completion_rate]
      completion > 50 ? "completed" : "active"
    else
      "pending"
    end
  end

  def get_admin_response_duration
    case @region
    when "bruxelles"
      "6-8 semaines"
    when "flandre"
      "4-6 semaines"
    else
      "4-6 semaines"
    end
  end

  def get_admin_response_weeks
    case @region
    when "bruxelles"
      8
    else
      6
    end
  end

  def add_seasonal_adjustments(phases)
    # Ajuster selon saison actuelle
    current_month = Date.current.month

    if [12, 1, 2].include?(current_month) && has_exterior_work?
      # Hiver : décaler travaux extérieurs
      work_phase = phases.find { |p| p[:name] == "Réalisation travaux" }
      if work_phase
        work_phase[:start_date] = Date.new(Date.current.year, 3, 1)
        work_phase[:note] = "⚠️ Travaux extérieurs reportés après hiver"
      end
    end

    phases
  end

  # Conditions
  def has_renolution_prime?
    @selected_primes.any? { |p| p[:name].include?("Renolution") }
  end

  def has_isolation_prime?
    @selected_primes.any? { |p| p[:category] == "isolation" }
  end

  def has_exterior_work?
    @selected_primes.any? { |p| ["isolation", "menuiserie"].include?(p[:category]) }
  end

  def missing_rge_quote?
    # Logique à connecter avec DocumentRequirementsService
    true # Placeholder
  end

  def missing_audit?
    # Logique à connecter avec DocumentRequirementsService
    true # Placeholder
  end

  def needs_urban_declaration?
    @region == "bruxelles" && has_isolation_prime?
  end

  def get_critical_steps
    # Les 5 étapes les plus cruciales basées sur la simulation
    base_steps = [
      {
        name: "Audit énergétique",
        duration: "2-3 semaines",
        status: determine_step_status("audit_energetique"),
        urgent: missing_audit?,
        deadline: 3.weeks.from_now,
        description: "Évaluation complète de la performance énergétique"
      },
      {
        name: "Constitution du dossier",
        duration: "1-2 semaines",
        status: determine_step_status("dossier"),
        urgent: true,
        deadline: 2.weeks.from_now,
        description: "Rassemblement de tous les documents requis"
      },
      {
        name: "Devis entrepreneurs",
        duration: "3-4 semaines",
        status: determine_step_status("devis"),
        urgent: missing_rge_quote?,
        deadline: 4.weeks.from_now,
        description: "Obtention et comparaison des devis de travaux"
      },
      {
        name: "Demande de prime",
        duration: "1 semaine",
        status: determine_step_status("prime_request"),
        urgent: true,
        deadline: 1.week.from_now,
        description: "Soumission du dossier complet de demande"
      },
      {
        name: "Début des travaux",
        duration: "Variable",
        status: determine_step_status("travaux"),
        urgent: false,
        deadline: 8.weeks.from_now,
        description: "Lancement effectif des travaux de rénovation"
      }
    ]

    # Adapter selon la simulation
    adapt_steps_to_simulation(base_steps)
  end

  def get_next_deadline
    # Prochaine échéance critique basée sur l'état du projet
    next_urgent_step = get_critical_steps.find { |step| step[:status] != 'completed' && step[:urgent] }

    if next_urgent_step
      {
        name: next_urgent_step[:name],
        date: next_urgent_step[:deadline],
        urgency: next_urgent_step[:deadline] < 1.week.from_now ? 'high' : 'medium'
      }
    else
      {
        name: "Prochaine étape planifiée",
        date: 2.weeks.from_now,
        urgency: 'low'
      }
    end
  end

  def determine_step_status(step_type)
    # Simulation du statut des étapes basé sur les données disponibles
    case step_type
    when "audit_energetique"
      missing_audit? ? 'pending' : ['completed', 'current'].sample
    when "dossier"
      ['current', 'pending'].sample
    when "devis"
      missing_rge_quote? ? 'pending' : ['pending', 'current'].sample
    when "prime_request"
      'pending'
    when "travaux"
      'pending'
    else
      'pending'
    end
  end

  def adapt_steps_to_simulation(steps)
    # Adapter les étapes selon le type de travaux de la simulation
    if has_isolation_prime?
      steps.first[:urgent] = true
      steps.first[:deadline] = 1.week.from_now if missing_audit?
    end

    if @region == "wallonie"
      steps.each { |step| step[:duration] = step[:duration].gsub(/(\d+)/, '\1-2') }
    end

    steps.take(5) # Limiter à 5 étapes critiques
  end
end
