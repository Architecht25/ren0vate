class Project < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :request, optional: true
  has_many :works, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :simulations, dependent: :destroy  # Ajouter cette ligne

  validates :nom, presence: true
  validates :property_id, presence: true

  # Définir un statut par défaut
  before_validation :set_default_status

  # Méthode pour affichage
  def name
    nom
  end

  # Méthode pour compatibilité
  def display_name
    "#{nom} (#{property&.name || 'Sans bien associé'})"
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
