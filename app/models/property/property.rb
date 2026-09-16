class Property < ApplicationRecord
  include PropertyCompletionScoring
  include PropertySaleReadiness
  include PropertyPebTrajectory
  include PropertyPhaseTracking

  self.inheritance_column = nil  # Désactiver l'héritage STI pour la colonne 'type'

  attr_accessor :skip_onboarding_validation

  serialize :elements_petit_patrimoine, coder: JSON

  belongs_to :user
  has_many :simulations, dependent: :destroy
  has_many :peb_donnees, dependent: :destroy
  has_many :audit_energ_donnees, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_many :tenants, dependent: :destroy
  has_many :leases, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :quotes, dependent: :destroy

  # Active Storage pour les images
  has_one_attached :photo

  # Géocodage
  geocoded_by :full_address
  after_validation :geocode, if: ->(obj) { obj.full_address.present? && (obj.rue_changed? || obj.numero_changed? || obj.code_postal_changed? || obj.commune_changed?) }

  # Statuts de vente
  enum :statut_vente, { actif: 'actif', en_vente: 'en_vente', vendu: 'vendu' }, prefix: false

  # Callback pour normaliser la région
  before_save :normalize_region

  # Validations pour les champs obligatoires essentiels — 5 champs communs à
  # toutes les régions, requis à la création ET à la mise à jour.
  validates :rue, :numero, :code_postal, :commune, :region, presence: true

  # Champ(s) régional/régionaux requis en plus des 5 champs communs ci-dessus,
  # mais seulement à la création (`new_record?`) — pas à la mise à jour, pour ne
  # pas bloquer l'édition de biens existants créés avant l'ajout de cette règle.
  # `skip_onboarding_validation` permet au tunnel d'onboarding (voir
  # OnboardingController#create_proprietaire_bien) de créer un bien avec les
  # 5 champs communs uniquement, région comprise — le reste (dont ce champ
  # régional) se complète ensuite depuis la fiche du bien.
  # État stable depuis mai 2026 — ce ne sont plus des validations "temporaires".
  validates :type_bien_flandre, presence: true, if: -> { region == 'flandre' && new_record? && !skip_onboarding_validation }
  validates :usage_flandre, presence: true, if: -> { region == 'flandre' && new_record? && !skip_onboarding_validation }
  validates :type_propriete_wallonie, presence: true, if: -> { region == 'wallonie' && new_record? && !skip_onboarding_validation }
  validates :type_bien_bruxelles, presence: true, if: -> { region == 'bruxelles' && new_record? && !skip_onboarding_validation }

  # Le reste des champs (année de construction, occupation, EAN, infos d'achat,
  # type de demandeur juridique...) n'a volontairement aucune validation de
  # présence : ce sont des informations à compléter au fil de l'eau depuis la
  # fiche du bien (`data_completeness_details`, `completion_percentage`), pas
  # des conditions bloquantes à la création ou à l'édition.

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

  # Méthodes pour la géolocalisation
  def geocoded?
    latitude.present? && longitude.present?
  end

  def coordinates
    [latitude, longitude] if geocoded?
  end

  def map_popup_content
    {
      name: name,
      address: full_address,
      price: valeur_achat,
      peb_value: peb_certificate_value,
      user_email: user&.email
    }
  end

  def peb_certificate_value
    case region&.downcase
    when 'wallonie'
      certificat_peb_wallonie
    when 'flandre'
      certificat_peb_flandre
    when 'bruxelles'
      certificat_peb_bruxelles
    else
      peb
    end
  end

  # Méthode pour identifier les biens d'entreprises
  def is_entreprise?
    # Une propriété est considérée comme entreprise si :
    # 1. Elle a le type "entreprise" dans la propriété elle-même, OU
    # 2. Elle a des simulations avec category = 'entreprise'
    type == 'entreprise' ||
    simulations.where(category: 'entreprise').exists?
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

  # Type et usage du bien selon le champ propre à sa région (chaque région a
  # sa propre colonne de type/usage sur Property). Centralisé ici après avoir
  # trouvé ce mapping copié-collé à l'identique dans 4 endroits (properties_controller,
  # requests_controller, decision_hub_controller, formulaire_preremplissage_helper).
  def mapped_type
    case region&.downcase
    when 'flandre'
      type_bien_flandre
    when 'wallonie'
      type_propriete_wallonie
    when 'bruxelles'
      type_bien_bruxelles
    else
      type
    end
  end

  def mapped_usage
    case region&.downcase
    when 'flandre'
      usage_flandre
    else
      usage || occupation
    end
  end

  private

  def normalize_region
    self.region = region&.downcase if region.present?
  end
end
