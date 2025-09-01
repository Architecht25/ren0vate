class DocumentPhaseCalculatorService
  include ActiveModel::Model

  attr_accessor :property

  def initialize(property)
    @property = property
  end

  # Calcule les métriques complètes pour toutes les phases
  def calculate_comprehensive_metrics
    phases_data = property.phases_with_status

    {
      overall_completion: calculate_overall_completion(phases_data),
      phases_summary: calculate_phases_summary(phases_data),
      next_actions: prioritize_next_actions(phases_data),
      timeline_estimation: estimate_timeline(phases_data),
      blocking_issues: identify_blocking_issues(phases_data),
      completion_roadmap: generate_completion_roadmap(phases_data)
    }
  end

  # Suggère des actions intelligentes basées sur l'état actuel
  def intelligent_recommendations
    phases_data = property.phases_with_status
    recommendations = []

    phases_data.each do |phase_data|
      phase = phase_data[:phase]
      status = phase_data[:phase_status]
      completion = phase_data[:completion_percentage]

      case status
      when 'not_started'
        if should_start_phase?(phase, phases_data)
          recommendations << {
            type: 'start_phase',
            priority: calculate_phase_priority(phase),
            phase: phase.name,
            message: "Commencer la #{phase.name.downcase}",
            actions: generate_start_actions(phase, phase_data)
          }
        end
      when 'started', 'in_progress'
        if completion < 50
          recommendations << {
            type: 'accelerate_phase',
            priority: 'medium',
            phase: phase.name,
            message: "Accélérer la progression de la #{phase.name.downcase}",
            actions: generate_acceleration_actions(phase, phase_data)
          }
        elsif completion >= 80
          recommendations << {
            type: 'complete_phase',
            priority: 'high',
            phase: phase.name,
            message: "Finaliser la #{phase.name.downcase}",
            actions: generate_completion_actions(phase, phase_data)
          }
        end
      when 'blocked'
        recommendations << {
          type: 'unblock_phase',
          priority: 'critical',
          phase: phase.name,
          message: "Débloquer la #{phase.name.downcase}",
          actions: generate_unblocking_actions(phase, phase_data)
        }
      end
    end

    recommendations.sort_by { |r| priority_weight(r[:priority]) }
  end

  # Détecte automatiquement les problèmes potentiels
  def detect_potential_issues
    issues = []
    phases_data = property.phases_with_status

    # Vérifier les documents rejetés
    rejected_docs = property.documents.where(status: 'rejected')
    if rejected_docs.any?
      issues << {
        type: 'rejected_documents',
        severity: 'high',
        message: "#{rejected_docs.count} document(s) rejeté(s) nécessitent une correction",
        affected_phases: find_affected_phases(rejected_docs),
        recommended_action: 'Corriger et réuploader les documents rejetés'
      }
    end

    # Vérifier les documents en attente depuis trop longtemps
    old_pending_docs = property.documents.where(status: 'pending')
                                         .where('created_at < ?', 7.days.ago)
    if old_pending_docs.any?
      issues << {
        type: 'stale_pending_documents',
        severity: 'medium',
        message: "#{old_pending_docs.count} document(s) en attente depuis plus de 7 jours",
        recommended_action: 'Relancer la validation ou vérifier le statut'
      }
    end

    # Vérifier les déséquilibres entre phases
    completion_variance = calculate_completion_variance(phases_data)
    if completion_variance > 30
      issues << {
        type: 'phase_imbalance',
        severity: 'medium',
        message: 'Progression déséquilibrée entre les phases',
        recommended_action: 'Équilibrer l\'avancement des phases'
      }
    end

    issues
  end

  # Génère un rapport de progression détaillé
  def generate_progress_report
    phases_data = property.phases_with_status

    {
      property: {
        name: property.name,
        address: property.full_address
      },
      generated_at: Time.current,
      overall_metrics: calculate_comprehensive_metrics,
      phase_details: phases_data.map { |data| format_phase_details(data) },
      issues: detect_potential_issues,
      recommendations: intelligent_recommendations.first(5),
      next_milestones: calculate_next_milestones(phases_data)
    }
  end

  private

  def calculate_overall_completion(phases_data)
    return 0 if phases_data.empty?

    total_completion = phases_data.sum { |data| data[:completion_percentage] }
    (total_completion.to_f / phases_data.count).round
  end

  def calculate_phases_summary(phases_data)
    summary = phases_data.group_by { |data| data[:phase_status] }

    {
      total_phases: phases_data.count,
      complete: (summary['complete'] || []).count,
      in_progress: (summary['in_progress'] || []).count + (summary['started'] || []).count,
      not_started: (summary['not_started'] || []).count,
      blocked: (summary['blocked'] || []).count
    }
  end

  def prioritize_next_actions(phases_data)
    actions = []

    phases_data.each do |phase_data|
      phase_actions = phase_data[:status].next_recommended_actions
      actions.concat(phase_actions.map { |action| action.merge(phase: phase_data[:phase]) })
    end

    actions.sort_by { |action| priority_weight(action[:priority]) }.first(3)
  end

  def estimate_timeline(phases_data)
    incomplete_phases = phases_data.reject { |data| data[:phase_status] == 'complete' }

    total_days = incomplete_phases.sum do |phase_data|
      case phase_data[:phase_status]
      when 'not_started' then 7 # Une semaine pour commencer
      when 'started' then 5 # 5 jours pour progresser
      when 'in_progress' then 3 # 3 jours pour finaliser
      when 'blocked' then 10 # 10 jours pour débloquer
      else 0
      end
    end

    {
      estimated_days: total_days,
      estimated_weeks: (total_days / 7.0).ceil,
      target_completion_date: total_days.days.from_now.to_date
    }
  end

  def should_start_phase?(phase, phases_data)
    # Logique pour déterminer si une phase peut/doit être démarrée
    # Par exemple, ne pas commencer la phase de réception si l'exécution n'est pas terminée

    case phase.position
    when 1 # Phase Administrative - peut toujours être démarrée
      true
    when 2 # Phase Technique - nécessite souvent la phase administrative
      admin_phase = phases_data.find { |data| data[:phase].position == 1 }
      admin_phase&.dig(:completion_percentage).to_i >= 50
    when 3 # Phase Exécution - nécessite la phase technique
      tech_phase = phases_data.find { |data| data[:phase].position == 2 }
      tech_phase&.dig(:completion_percentage).to_i >= 70
    when 4 # Phase Réception - nécessite la phase exécution
      exec_phase = phases_data.find { |data| data[:phase].position == 3 }
      exec_phase&.dig(:completion_percentage).to_i >= 80
    else
      true
    end
  end

  def calculate_phase_priority(phase)
    case phase.position
    when 1 then 'high'    # Phase Administrative prioritaire
    when 2 then 'high'    # Phase Technique critique
    when 3 then 'medium'  # Phase Exécution importante
    when 4 then 'low'     # Phase Réception finale
    else 'medium'
    end
  end

  def priority_weight(priority)
    case priority&.to_s
    when 'critical' then 0
    when 'high' then 1
    when 'medium' then 2
    when 'low' then 3
    else 4
    end
  end

  def generate_start_actions(phase, phase_data)
    missing_required = phase_data[:missing_required]

    actions = []

    if missing_required.any?
      actions << "Préparer les documents requis : #{missing_required.join(', ')}"
    end

    actions << "Consulter les conditions spécifiques de la #{phase.name.downcase}"
    actions << "Planifier les étapes de cette phase"

    actions
  end

  def generate_acceleration_actions(phase, phase_data)
    [
      "Compléter les documents manquants",
      "Vérifier les documents en attente",
      "Contacter les prestataires si nécessaire"
    ]
  end

  def generate_completion_actions(phase, phase_data)
    [
      "Vérifier la complétude de tous les documents",
      "Valider la qualité des documents soumis",
      "Finaliser la phase avant de passer à la suivante"
    ]
  end

  def generate_unblocking_actions(phase, phase_data)
    [
      "Identifier la cause du blocage",
      "Corriger les documents rejetés",
      "Obtenir les autorisations manquantes"
    ]
  end

  def find_affected_phases(documents)
    phases = []

    documents.each do |doc|
      phase = DocumentPhase.find_phase_for_document_type(doc.type_document)
      phases << phase.name if phase
    end

    phases.uniq
  end

  def calculate_completion_variance(phases_data)
    completions = phases_data.map { |data| data[:completion_percentage] }
    return 0 if completions.empty?

    avg = completions.sum.to_f / completions.count
    variance = completions.sum { |c| (c - avg) ** 2 } / completions.count
    Math.sqrt(variance).round
  end

  def format_phase_details(phase_data)
    {
      name: phase_data[:phase].name,
      description: phase_data[:phase].description,
      completion_percentage: phase_data[:completion_percentage],
      status: phase_data[:phase_status],
      required_documents: phase_data[:phase].required_document_types,
      optional_documents: phase_data[:phase].optional_document_types,
      missing_required: phase_data[:missing_required],
      missing_optional: phase_data[:missing_optional],
      next_actions: phase_data[:status].next_recommended_actions
    }
  end

  def calculate_next_milestones(phases_data)
    milestones = []

    phases_data.each do |phase_data|
      unless phase_data[:phase_status] == 'complete'
        milestones << {
          phase: phase_data[:phase].name,
          target_date: estimate_phase_completion_date(phase_data),
          priority: calculate_phase_priority(phase_data[:phase])
        }
      end
    end

    milestones.sort_by { |m| m[:target_date] }.first(3)
  end

  def estimate_phase_completion_date(phase_data)
    days_to_add = case phase_data[:phase_status]
                  when 'not_started' then 14
                  when 'started' then 10
                  when 'in_progress' then 5
                  when 'blocked' then 21
                  else 7
                  end

    days_to_add.days.from_now.to_date
  end

  # Identifie les problèmes bloquants
  def identify_blocking_issues(phases_data)
    issues = []

    phases_data.each do |phase_data|
      phase = phase_data[:phase]
      status = phase_data[:phase_status]

      # Documents rejetés pour cette phase
      rejected_docs = property.documents
                             .where(type_document: phase.required_document_types)
                             .where(status: 'rejected')

      if rejected_docs.any?
        issues << {
          type: 'rejected_documents',
          severity: 'high',
          phase: phase.name,
          message: "#{rejected_docs.count} document(s) rejeté(s) en #{phase.name}",
          documents: rejected_docs,
          resolution: "Corriger et re-soumettre les documents rejetés"
        }
      end

      # Documents manquants critiques
      missing_critical = phase.missing_required_documents_for_property(property)
      if missing_critical.any? && status != :pending
        issues << {
          type: 'missing_critical',
          severity: 'medium',
          phase: phase.name,
          message: "Documents obligatoires manquants : #{missing_critical.join(', ')}",
          documents: missing_critical,
          resolution: "Fournir les documents obligatoires"
        }
      end

      # Phase bloquée
      if status == :blocked
        issues << {
          type: 'phase_blocked',
          severity: 'high',
          phase: phase.name,
          message: "Phase #{phase.name} bloquée",
          resolution: "Identifier et résoudre les obstacles"
        }
      end
    end

    issues.sort_by { |issue| issue[:severity] == 'high' ? 0 : 1 }
  end

  # Génère une feuille de route de completion
  def generate_completion_roadmap(phases_data)
    roadmap = []
    current_date = Date.current

    phases_data.each_with_index do |phase_data, index|
      phase = phase_data[:phase]
      status = phase_data[:phase_status]
      completion = phase_data[:completion_percentage]

      estimated_start = current_date + (index * 7).days
      estimated_duration = estimate_phase_duration(phase, completion)
      estimated_end = estimated_start + estimated_duration.days

      roadmap << {
        phase: phase.name,
        order: index + 1,
        status: status,
        completion_percentage: completion,
        estimated_start: estimated_start,
        estimated_end: estimated_end,
        duration_days: estimated_duration,
        dependencies: calculate_dependencies(phase, phases_data),
        critical_path: is_critical_path?(phase, phases_data)
      }

      current_date = estimated_end + 1.day
    end

    roadmap
  end

  private

  def estimate_phase_duration(phase, current_completion)
    base_duration = case phase.name
                   when /Administrative/i then 7
                   when /Technical/i then 14
                   when /Execution/i then 30
                   when /Reception/i then 10
                   else 10
                   end

    # Ajuster selon le progrès actuel
    remaining_work = [(100 - current_completion) / 100.0, 0.1].max
    (base_duration * remaining_work).ceil
  end

  def calculate_dependencies(phase, phases_data)
    # Les phases suivent généralement un ordre séquentiel
    case phase.name
    when /Technical/i
      ['Phase Administrative']
    when /Execution/i
      ['Phase Administrative', 'Phase Technique']
    when /Reception/i
      ['Phase Administrative', 'Phase Technique', 'Phase d\'Exécution']
    else
      []
    end
  end

  def is_critical_path?(phase, phases_data)
    # Une phase est sur le chemin critique si elle a des documents obligatoires
    phase.required_document_types.any?
  end
end
