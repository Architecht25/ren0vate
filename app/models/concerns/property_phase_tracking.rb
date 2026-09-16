module PropertyPhaseTracking
  extend ActiveSupport::Concern

  included do
    has_many :document_phase_statuses, dependent: :destroy
    has_many :document_phases, through: :document_phase_statuses

    after_create :initialize_document_phases
    after_find :ensure_document_phases_exist
  end

  # Récupère ou crée le statut d'une phase pour cette propriété
  def phase_status_for(document_phase)
    document_phase_statuses.find_or_create_by(document_phase: document_phase) do |status|
      status.refresh_status!
    end
  end

  # Calcule le pourcentage de complétude global par phases
  def phases_completion_percentage
    statuses = document_phase_statuses.includes(:document_phase)
    return 0 if statuses.empty?

    total_percentage = statuses.sum(&:completion_percentage)
    (total_percentage.to_f / statuses.count).round
  end

  # Récupère toutes les phases avec leurs statuts pour cette propriété
  def phases_with_status
    phases_scope = determine_phase_category == 'investissement' ?
                     DocumentPhase.investissement.ordered :
                     DocumentPhase.chantier.ordered

    phases_scope.includes(:document_phase_statuses).map do |phase|
      {
        phase: phase,
        status: phase_status_for(phase),
        completion_percentage: phase.completion_percentage_for_property(self),
        phase_status: phase.status_for_property(self),
        missing_required: phase.missing_required_documents_for_property(self),
        missing_optional: phase.missing_optional_documents_for_property(self)
      }
    end
  end

  # Détermine si cette propriété utilise les phases chantier ou investissement
  #
  # BUG PROD (22/08/2026) : cette méthode interrogeait `projects.finalite`, colonne
  # supprimée par la migration RemoveEntrepriseColumnsFromPropertiesAndProjects
  # (20260308164557) lors de l'abandon de la fonctionnalité "Entreprises Bruxelles".
  # Provoquait un PG::UndefinedColumn (500) sur toute propriété où `is_entreprise?`
  # est vrai — ex. /projects/:id/documents. La fonctionnalité étant abandonnée, les
  # phases "investissement" ne sont plus jamais pertinentes : on retombe sur "chantier".
  def determine_phase_category
    'chantier'
  end

  # Phases en cours ou bloquées nécessitant attention
  def phases_needing_attention
    phases_with_status.select do |phase_data|
      ['not_started', 'blocked', 'started'].include?(phase_data[:phase_status])
    end
  end

  # Prochaine phase à compléter
  def next_phase_to_complete
    phases_needing_attention.first
  end

  # Documents manquants critiques pour toutes les phases
  def critical_missing_documents
    DocumentPhase.ordered.flat_map do |phase|
      phase.missing_required_documents_for_property(self)
    end.uniq
  end

  # Obtient les actions recommandées pour les phases
  def recommended_phase_actions
    actions = []

    phases_with_status.each do |phase_data|
      phase = phase_data[:phase]
      status = phase_data[:status]

      phase_actions = status.next_recommended_actions
      phase_actions.each do |action|
        actions << action.merge(phase: phase.name, phase_id: phase.id)
      end
    end

    # Trier par priorité (high, medium, low)
    priority_order = { 'high' => 1, 'medium' => 2, 'low' => 3 }
    actions.sort_by { |action| priority_order[action[:priority]] || 4 }
  end

  # Met à jour les statuts de toutes les phases
  def refresh_all_phase_statuses!
    DocumentPhase.ordered.each do |phase|
      phase_status_for(phase).refresh_status!
    end
  end

  # Vérifie si toutes les phases sont complètes
  def all_phases_complete?
    phases_with_status.all? { |data| ['complete', 'nearly_complete'].include?(data[:phase_status]) }
  end

  # Temps estimé pour compléter toutes les phases restantes
  def estimated_completion_time_all_phases
    incomplete_phases = phases_with_status.reject { |data| data[:phase_status] == 'complete' }

    case incomplete_phases.count
    when 0
      'Terminé'
    when 1
      incomplete_phases.first[:status].estimated_completion_time
    when 2..3
      '1-2 semaines'
    else
      '3-4 semaines'
    end
  end

  private

  # Callback pour initialiser les phases de documents après création
  def initialize_document_phases
    # S'assurer que les phases par défaut existent
    DocumentPhase.create_default_phases!

    # Créer les statuts pour toutes les phases
    DocumentPhase.ordered.each do |phase|
      phase_status_for(phase)
    end
  end

  # S'assurer que les phases existent pour les propriétés existantes
  def ensure_document_phases_exist
    return if new_record? || document_phase_statuses.any?

    # Initialiser les phases si elles n'existent pas
    begin
      initialize_document_phases
    rescue => e
      Rails.logger.warn "Erreur lors de l'initialisation des phases pour la propriété #{id}: #{e.message}"
    end
  end
end
