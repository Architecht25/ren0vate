class Project < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :request, optional: true
  has_many :documents, dependent: :destroy
  has_many :simulations, dependent: :destroy  # Ajouter cette ligne

  validates :nom, presence: true
  validates :property_id, presence: true
  validates :project_type, presence: true, inclusion: { in: %w[renovation investment],
                                                       message: "doit être 'renovation' ou 'investment'" }
  validates :finalite, presence: true, inclusion: { in: %w[residentielle economique],
                                                   message: "doit être 'residentielle' ou 'economique'" }

  # Définir un statut et type par défaut
  before_validation :set_default_status
  before_validation :set_default_project_type

  # Sérialisation JSON pour les champs complexes
  serialize :architecte_specialites, coder: JSON
  serialize :entrepreneur_principal_certifications, coder: JSON
  serialize :corps_metiers, coder: JSON
  serialize :garanties_travaux, coder: JSON

  # Méthodes pour les types de projets
  def renovation?
    project_type == 'renovation'
  end

  def investment?
    project_type == 'investment'
  end

  # Méthodes pour les finalités
  def finalite_residentielle?
    finalite == 'residentielle'
  end

  def finalite_economique?
    finalite == 'economique'
  end

  def type_display
    case project_type
    when 'renovation'
      'Chantier de rénovation'
    when 'investment'
      'Investissement d\'entreprise'
    else
      project_type.humanize
    end
  end

  # Méthode pour affichage
  def name
    nom
  end

  # Méthode pour compatibilité
  def display_name
    "#{nom} (#{property&.name || 'Sans bien associé'})"
  end

  # Méthodes pour les professionnels
  def architecte_nom_complet
    [architecte_prenom, architecte_nom].compact.join(' ')
  end

  def architecte_complet?
    architecte_nom.present? && architecte_prenom.present? && architecte_email.present?
  end

  def entrepreneur_principal_complet?
    entrepreneur_principal_nom.present? && entrepreneur_principal_entreprise.present?
  end

  def has_coordinateur_securite?
    coordinateur_securite_nom.present?
  end

  # Méthodes pour gérer les corps de métiers (stockés en JSON)
  def corps_metiers_list
    corps_metiers || []
  end

  def add_corps_metier(nom:, entreprise:, contact: nil, specialite: nil)
    self.corps_metiers ||= []
    self.corps_metiers << {
      nom: nom,
      entreprise: entreprise,
      contact: contact,
      specialite: specialite,
      ajoute_le: Time.current
    }
  end

  def remove_corps_metier(index)
    return unless corps_metiers && corps_metiers[index]
    self.corps_metiers.delete_at(index)
  end

  # Gestion des types de travaux Flandre
  def type_travaux_array
    return [] if type_travaux.blank?
    type_travaux.split(',').map(&:strip)
  end

  def type_travaux_array=(array)
    self.type_travaux = array.reject(&:blank?).join(',')
  end

  # Méthodes virtuelles pour les checkboxes
  def type_travaux_isolation
    type_travaux_array.include?('isolation')
  end

  def type_travaux_isolation=(value)
    update_type_travaux('isolation', value == '1')
  end

  def type_travaux_chauffage
    type_travaux_array.include?('chauffage')
  end

  def type_travaux_chauffage=(value)
    update_type_travaux('chauffage', value == '1')
  end

  def type_travaux_ventilation
    type_travaux_array.include?('ventilation')
  end

  def type_travaux_ventilation=(value)
    update_type_travaux('ventilation', value == '1')
  end

  def type_travaux_fenetres
    type_travaux_array.include?('fenetres')
  end

  def type_travaux_fenetres=(value)
    update_type_travaux('fenetres', value == '1')
  end

  def type_travaux_toiture
    type_travaux_array.include?('toiture')
  end

  def type_travaux_toiture=(value)
    update_type_travaux('toiture', value == '1')
  end

  def type_travaux_autre
    type_travaux_array.include?('autre')
  end

  def type_travaux_autre=(value)
    update_type_travaux('autre', value == '1')
  end

  private

  def set_default_status
    self.statut ||= 'preparation'
  end

  def set_default_project_type
    self.project_type ||= 'renovation'
  end

  def update_type_travaux(type, should_include)
    current_types = type_travaux_array
    if should_include
      current_types << type unless current_types.include?(type)
    else
      current_types.delete(type)
    end
    self.type_travaux = current_types.join(',')
  end
end
