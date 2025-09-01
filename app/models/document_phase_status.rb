class DocumentPhaseStatus < ApplicationRecord
  belongs_to :property
  belongs_to :document_phase

  validates :property, presence: true
  validates :document_phase, presence: true
  validates :property_id, uniqueness: { scope: :document_phase_id }

  # Status de la phase pour cette propriété
  enum :status, {
    pending: 0,        # Au lieu de not_started
    started: 1,
    in_progress: 2,
    nearly_complete: 3,
    complete: 4,
    blocked: 5
  }

  # Scopes utiles
  scope :for_property, ->(property) { where(property: property) }
  scope :completed, -> { where(status: [:complete, :nearly_complete]) }
  scope :in_progress, -> { where(status: [:started, :in_progress]) }
  scope :needs_attention, -> { where(status: [:pending, :blocked]) }

  # Callbacks pour maintenir les statuts à jour
  before_save :calculate_completion_percentage
  before_save :update_status_based_on_documents

  # Mettre à jour le statut basé sur les documents de la propriété
  def refresh_status!
    update_status_based_on_documents
    save! if changed?
  end

  # Calculer le pourcentage de complétion
  def calculate_completion_percentage
    self.completion_percentage = document_phase.completion_percentage_for_property(property)
  end

  # Vérifier s'il y a des blocages
  def has_blocking_issues?
    # Vérifier les documents rejetés
    rejected_docs = property.documents
                            .where(type_document: document_phase.required_document_types)
                            .where(status: 'rejected')

    # Vérifier les documents expirés (si applicable)
    # Ici on pourrait ajouter une logique pour les documents avec dates d'expiration

    rejected_docs.exists?
  end

  # Documents manquants critiques
  def critical_missing_documents
    document_phase.missing_required_documents_for_property(property)
  end

  # Prochaines actions recommandées
  def next_recommended_actions
    actions = []
    missing_required = critical_missing_documents

    if missing_required.any?
      actions << {
        type: 'upload_required',
        priority: 'high',
        message: "Ajouter les documents obligatoires : #{missing_required.join(', ')}",
        document_types: missing_required
      }
    end

    missing_optional = document_phase.missing_optional_documents_for_property(property)
    if missing_optional.any? && missing_required.empty?
      actions << {
        type: 'upload_optional',
        priority: 'medium',
        message: "Compléter avec les documents optionnels : #{missing_optional.first(3).join(', ')}",
        document_types: missing_optional.first(3)
      }
    end

    # Vérifier les documents en attente d'approbation
    pending_docs = property.documents
                           .where(type_document: document_phase.required_document_types + document_phase.optional_document_types)
                           .where(status: 'pending')

    if pending_docs.any?
      actions << {
        type: 'review_pending',
        priority: 'medium',
        message: "#{pending_docs.count} document(s) en attente de validation",
        documents: pending_docs
      }
    end

    actions
  end

  # Délai estimé pour compléter la phase
  def estimated_completion_time
    missing_count = critical_missing_documents.count

    case missing_count
    when 0
      'Immédiat'
    when 1..2
      '1-2 jours'
    when 3..5
      '3-5 jours'
    else
      '1-2 semaines'
    end
  end

  private

  def update_status_based_on_documents
    if has_blocking_issues?
      self.status = :blocked
    else
      self.status = document_phase.status_for_property(property)
    end
  end
end
