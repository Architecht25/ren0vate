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

  # Types uploadés au niveau profil utilisateur (sans property_id)
  USER_LEVEL_TYPES = %w[aer rib].freeze

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
      required_document_types: ['aer', 'rib', 'certificat_peb_avant'],
      optional_document_types: ['permis_urbanisme', 'plan', 'dossier_prime', 'acte_notarial', 'compromis']
    },
    {
      name: 'Phase Technique',
      description: 'Plans, devis et études techniques',
      icon: '🔧',
      color: 'info',
      position: 2,
      required_document_types: ['devis', 'bordereau_chassis', 'certificat_label', 'rapport_audit_energetique'],
      optional_document_types: []
    },
    {
      name: 'Phase Exécution',
      description: 'Factures, états d\'avancement et rapports de chantier',
      icon: '📋',
      color: 'warning',
      position: 3,
      required_document_types: ['facture', 'attestation_entrepreneur', 'photo_chassis'],
      optional_document_types: ['etat_avancement', 'photo_avant', 'photo_pendant', 'photo_apres']
    },
    {
      name: 'Phase Réception',
      description: 'Conformité, garanties et finalisation - Documents DIU',
      icon: '✅',
      color: 'success',
      position: 4,
      required_document_types: ['certificat_peb_apres', 'attestation_conformite'],
      optional_document_types: ['plan_diu', 'fiche_technique', 'notice_equipement', 'fiche_securite_materiaux', 'certificat_garantie', 'instruction_entretien']
    }
  ].freeze

  # Calcule le pourcentage de complétude pour une propriété donnée
  def completion_percentage_for_property(property)
    return 0 unless property

    total_types = (required_document_types + optional_document_types).uniq
    return 100 if total_types.empty?

    required_completed = existing_type_names(property, required_document_types).count
    optional_completed = existing_type_names(property, optional_document_types).count

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

    existing_approved = existing_type_names(property, required_document_types, approved_only: true)
    required_document_types - existing_approved
  end

  # Documents optionnels manquants pour une propriété
  def missing_optional_documents_for_property(property)
    return optional_document_types if property.nil?

    existing = existing_type_names(property, optional_document_types)
    optional_document_types - existing
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

  private

  # Retourne les type_document existants pour une phase, en incluant les docs
  # uploadés au niveau profil (sans property_id) pour les types USER_LEVEL_TYPES.
  def existing_type_names(property, types, approved_only: false)
    return [] if types.empty?

    # Docs liés au bien
    property_scope = property.documents.where(type_document: types)
    property_scope = property_scope.where(status: 'approved') if approved_only
    found = property_scope.distinct.pluck(:type_document)

    # Docs utilisateur sans property_id (aer, rib…)
    user_level = types & USER_LEVEL_TYPES
    if user_level.any?
      user_scope = property.user.documents.where(property_id: nil, type_document: user_level)
      user_scope = user_scope.where(status: 'approved') if approved_only
      found |= user_scope.distinct.pluck(:type_document)
    end

    found
  end
end
