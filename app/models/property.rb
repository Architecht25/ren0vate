class Property < ApplicationRecord
  self.inheritance_column = nil  # Désactiver l'héritage STI pour la colonne 'type'

  belongs_to :user
  has_many :simulations
  has_many :projects
  has_many :requests
  has_many :documents

  # Validations pour les champs obligatoires essentiels
  validates :rue, :numero, :code_postal, :commune, :region, presence: true

  # Validations régionales conditionnelles
  validates :type_bien_flandre, presence: true, if: -> { region == 'flandre' }
  validates :type_propriete_wallonie, presence: true, if: -> { region == 'wallonie' }

  # Validations optionnelles - à réactiver plus tard selon les besoins
  # validates :type, :occupation, presence: true
  # validates :annee_construction, :date_raccordement_electrique, :numero_ean, presence: true, if: :strict_validation_required?

  # Validations pour les champs radio - temporairement désactivées
  # validates :autre_bien, inclusion: { in: %w[oui non] }, allow_blank: true
  # validates :peb, inclusion: { in: %w[ef autre] }, allow_blank: true
  # validates :reconstruit, inclusion: { in: %w[oui non] }, allow_blank: true

  # Méthode pour l'adresse complète
  def full_address
    "#{numero} #{rue}, #{code_postal} #{commune}"
  end

  # Méthode pour compatibilité avec les vues existantes
  def address
    full_address
  end

  def location
    full_address
  end

  # Méthodes pour les dashboards et le suivi de complétude
  def completion_percentage
    # Calcul de complétude incluant les documents
    admin_weight = 0.3
    chantier_weight = 0.3
    primes_weight = 0.2
    documents_weight = 0.2

    overall = (admin_completion_percentage * admin_weight +
               chantier_completion_percentage * chantier_weight +
               primes_completion_percentage * primes_weight +
               documents_completion_percentage * documents_weight)

    overall.round
  end

  def admin_completion_percentage
    admin_fields = admin_fields_for_region
    total = admin_fields.count
    completed = admin_fields.count { |field| self[field].present? }
    return 0 if total.zero?
    (completed.to_f / total * 100).round
  end

  def chantier_completion_percentage
    chantier_fields = chantier_fields_for_region
    total = chantier_fields.count
    completed = chantier_fields.count { |field| self[field].present? }
    return 0 if total.zero?
    (completed.to_f / total * 100).round
  end

  def primes_completion_percentage
    # Pour l'instant, on se base sur la présence d'au moins une simulation
    simulations.any? ? 100 : 0
  end

  def ready_for_request?
    completion_percentage >= 80
  end

  def completion_status
    percentage = completion_percentage
    case percentage
    when 0...30 then 'danger'
    when 30...70 then 'warning'
    when 70...90 then 'info'
    else 'success'
    end
  end

  def admin_completion_class
    case admin_completion_percentage
    when 0...50 then 'bg-danger'
    when 50...80 then 'bg-warning'
    else 'bg-success'
    end
  end

  def chantier_completion_class
    case chantier_completion_percentage
    when 0...50 then 'bg-danger'
    when 50...80 then 'bg-warning'
    else 'bg-success'
    end
  end

  def primes_completion_class
    primes_completion_percentage > 0 ? 'bg-success' : 'bg-secondary'
  end

  def name
    # Génère un nom basé sur le type et la localisation selon la région
    begin
      type_display = case region&.downcase
                     when 'wallonie'
                       type_propriete_wallonie&.humanize || 'Bien'
                     when 'flandre'
                       type_bien_flandre&.humanize || 'Bien'
                     when 'bruxelles'
                       type_bien_bruxelles&.humanize || 'Bien'
                     else
                       type&.humanize || 'Bien'
                     end
      location_name = commune.present? ? commune : 'Sans adresse'
      "#{type_display} #{location_name}"
    rescue => e
      Rails.logger.error "Property#name error for property #{id}: #{e.message}"
      "Bien #{commune || id}"
    end
  end

  def missing_required_fields
    required_fields.select { |field| self[field].blank? }
  end

  # Méthode de debug pour voir quels champs sont évalués
  def completion_debug_info
    {
      region: region,
      admin_fields: admin_fields_for_region,
      admin_completed: admin_fields_for_region.select { |field| self[field].present? },
      admin_missing: admin_fields_for_region.select { |field| self[field].blank? },
      chantier_fields: chantier_fields_for_region,
      chantier_completed: chantier_fields_for_region.select { |field| self[field].present? },
      chantier_missing: chantier_fields_for_region.select { |field| self[field].blank? }
    }
  end

  # Méthodes pour les documents
  def documents_completion_percentage
    stats = Document.completion_stats_for_property(self)
    stats[:percentage]
  end

  def documents_completion_class
    case documents_completion_percentage
    when 0...50 then 'bg-danger'
    when 50...80 then 'bg-warning'
    else 'bg-success'
    end
  end

  def completed_documents_count
    stats = Document.completion_stats_for_property(self)
    stats[:completed]
  end

  def total_required_documents
    stats = Document.completion_stats_for_property(self)
    stats[:total]
  end

  def documents_by_type
    documents.group_by(&:type_document)
  end

  # Méthodes pour le formulaire miroir
  def ready_for_submission?
    admin_completion_percentage >= 80 &&
    chantier_completion_percentage >= 60 &&
    documents_completion_percentage >= 80
  end

  def missing_for_submission
    missing = []
    missing << "Informations administratives incomplètes" if admin_completion_percentage < 80
    missing << "Informations chantier incomplètes" if chantier_completion_percentage < 60
    missing << "Documents manquants" if documents_completion_percentage < 80
    missing
  end

  def has_travaux?(type)
    # À adapter selon votre logique de travaux
    # Pour l'instant, retourne false - à implémenter avec vos données
    false
  end

  def submission_readiness_class
    if ready_for_submission?
      'bg-success'
    elsif completion_percentage >= 50
      'bg-warning'
    else
      'bg-danger'
    end
  end

  private

  def admin_fields_for_region
    # Champs de base communs à toutes les régions
    fields = [:rue, :numero, :code_postal, :commune, :region]

    # Ajout des champs régionaux selon la région
    case region
    when 'wallonie'
      fields += [:type_propriete_wallonie, :certificat_peb_wallonie]
    when 'flandre'
      fields += [:type_bien_flandre, :usage_flandre, :certificat_peb_flandre]
    when 'bruxelles'
      fields += [:type_bien_bruxelles, :certificat_peb_bruxelles]
    else
      # Fallback vers l'ancien champ générique si pas de région définie
      fields += [:type] if respond_to?(:type)
    end

    fields
  end

  def chantier_fields_for_region
    # Champs de base communs à toutes les régions
    fields = [:annee_construction]

    # Ajout des champs régionaux spécifiques selon la région
    case region
    when 'wallonie'
      # Pour la Wallonie : surface habitable et mode de chauffage
      fields += [:surface_habitable_wallonie, :mode_chauffage_wallonie]
    when 'flandre'
      # Pour la Flandre : système chauffage, EAN et parcelle spécifiques Flandre
      fields += [:chauffage_post_renovation_flandre, :ean_flandre, :parcelle_flandre]
    when 'bruxelles'
      # Pour Bruxelles : champs spécifiques à définir
      fields += []
    else
      # Fallback vers les anciens champs génériques si pas de région définie
      fields += [:date_raccordement_electrique, :numero_ean, :autre_bien, :peb]
    end

    fields
  end

  def required_fields
    # Champs minimum requis pour l'enregistrement
    fields = [:rue, :numero, :code_postal, :commune, :region]

    # Ajout des champs régionaux requis selon la région
    case region
    when 'wallonie'
      fields += [:type_propriete_wallonie]
    when 'flandre'
      fields += [:type_bien_flandre]
    when 'bruxelles'
      fields += [:type_bien_bruxelles]
    end

    fields
  end

  def strict_validation_required?
    # Pour l'instant, on désactive les validations strictes pour permettre la création
    # Elles peuvent être activées plus tard selon la logique métier
    false
  end
end
