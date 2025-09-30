class DocumentPhase < ApplicationRecord
  has_many :document_phase_statuses, dependent: :destroy
  has_many :properties, through: :document_phase_statuses

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true, uniqueness: true
  validates :description, presence: true
  validates :color, presence: true
  validates :icon, presence: true
  validates :category, presence: true, inclusion: { in: %w[chantier investissement] }

  scope :ordered, -> { order(:position) }
  scope :chantier, -> { where(category: 'chantier') }
  scope :investissement, -> { where(category: 'investissement') }

  # Les colonnes JSON sont automatiquement gérées par Rails 8
  # Plus besoin de serialize pour les colonnes JSON

  # Phases prédéfinies par défaut
  DEFAULT_PHASES = [
    {
      name: 'Phase Administrative',
      description: 'Permis, autorisations et diagnostics réglementaires',
      icon: '🏛️',
      color: 'primary',
      position: 1,
      required_document_types: ['permis_urbanisme', 'certificat_peb'],
      optional_document_types: ['plan', 'dossier_prime', 'acte_notarial', 'compromis']
    },
    {
      name: 'Phase Technique',
      description: 'Plans, devis et études techniques',
      icon: '🔧',
      color: 'info',
      position: 2,
      required_document_types: ['devis', 'bordereau_chassis', 'certificat_label'],
      optional_document_types: []
    },
    {
      name: 'Phase Exécution',
      description: 'Factures, états d\'avancement et rapports de chantier',
      icon: '📋',
      color: 'warning',
      position: 3,
      required_document_types: ['facture', 'attestation_entrepreneur', 'photo_chassis'],
      optional_document_types: ['etat_avancement', 'photo', 'attestation_conformite']
    },
    {
      name: 'Phase Réception',
      description: 'Conformité, garanties et finalisation',
      icon: '✅',
      color: 'success',
      position: 4,
      required_document_types: ['certificat_peb', 'attestation_conformite'],
      optional_document_types: ['certificat_protection', 'photo']
    }
  ].freeze

  # Calcule le pourcentage de complétude pour une propriété donnée
  def completion_percentage_for_property(property)
    return 0 unless property

    total_types = (required_document_types + optional_document_types).uniq
    return 100 if total_types.empty?

    completed_types = property.documents
                              .where(type_document: total_types)
                              .where(status: 'approved')
                              .distinct
                              .count(:type_document)

    # Pondération : documents requis comptent plus
    required_completed = property.documents
                                 .where(type_document: required_document_types)
                                 .where(status: 'approved')
                                 .distinct
                                 .count(:type_document)

    optional_completed = property.documents
                                 .where(type_document: optional_document_types)
                                 .where(status: 'approved')
                                 .distinct
                                 .count(:type_document)

    # Score pondéré : 70% pour les requis, 30% pour les optionnels
    total_required = required_document_types.count
    total_optional = optional_document_types.count

    if total_required > 0 && total_optional > 0
      required_score = (required_completed.to_f / total_required) * 70
      optional_score = (optional_completed.to_f / total_optional) * 30
      (required_score + optional_score).round
    elsif total_required > 0
      ((required_completed.to_f / total_required) * 100).round
    elsif total_optional > 0
      ((optional_completed.to_f / total_optional) * 100).round
    else
      0
    end
  end

  # Détermine le statut de la phase pour une propriété
  def status_for_property(property)
    percentage = completion_percentage_for_property(property)
    missing_required = missing_required_documents_for_property(property)

    if percentage >= 100 && missing_required.empty?
      :complete
    elsif percentage >= 80 && missing_required.empty?
      :nearly_complete
    elsif percentage >= 50 || missing_required.count < required_document_types.count / 2
      :in_progress
    elsif percentage > 0
      :started
    else
      :pending  # Au lieu de not_started
    end
  end

  # Documents requis manquants pour une propriété
  def missing_required_documents_for_property(property)
    return required_document_types if property.nil?

    existing_approved_types = property.documents
                                      .where(status: 'approved')
                                      .pluck(:type_document)

    required_document_types - existing_approved_types
  end

  # Documents optionnels manquants pour une propriété
  def missing_optional_documents_for_property(property)
    return optional_document_types if property.nil?

    existing_types = property.documents.pluck(:type_document)
    optional_document_types - existing_types
  end

  # Classe CSS pour la couleur de la phase
  def color_class
    case status_for_property(nil) # Status par défaut
    when :complete, :nearly_complete
      'success'
    when :in_progress, :started
      'warning'
    else
      'danger'
    end
  end

  # Icône de statut
  def status_icon_for_property(property)
    case status_for_property(property)
    when :complete
      '✅'
    when :nearly_complete
      '🟢'
    when :in_progress
      '🟡'
    when :started
      '🟠'
    else
      '🔴'
    end
  end

  # Méthode pour créer les phases par défaut
  def self.create_default_phases!
    transaction do
      DEFAULT_PHASES.each do |phase_data|
        find_or_create_by(name: phase_data[:name]) do |phase|
          phase.assign_attributes(phase_data)
        end
      end
    end
  end

  # Mapping intelligent : trouve la phase appropriée pour un type de document
  def self.find_phase_for_document_type(document_type)
    ordered.find do |phase|
      phase.required_document_types.include?(document_type) ||
      phase.optional_document_types.include?(document_type)
    end
  end
end
