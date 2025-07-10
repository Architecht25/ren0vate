class Property < ApplicationRecord
  self.inheritance_column = nil  # Désactiver l'héritage STI pour la colonne 'type'

  belongs_to :user
  has_many :simulations
  has_many :projects
  has_many :requests
  has_many :documents

  # Validations pour les champs obligatoires
  validates :rue, :numero, :code_postal, :commune, :region, presence: true
  validates :type, :occupation, presence: true
  validates :annee_construction, :date_raccordement_electrique, :numero_ean, presence: true

  # Validations pour les champs radio
  validates :autre_bien, inclusion: { in: %w[oui non] }, allow_blank: true
  validates :peb, inclusion: { in: %w[ef autre] }, allow_blank: true

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
    total_fields = required_fields.count
    completed_fields = required_fields.count { |field| self[field].present? }
    return 0 if total_fields.zero?
    (completed_fields.to_f / total_fields * 100).round
  end

  def admin_completion_percentage
    admin_fields = [:rue, :numero, :code_postal, :commune, :type, :region]
    total = admin_fields.count
    completed = admin_fields.count { |field| self[field].present? }
    return 0 if total.zero?
    (completed.to_f / total * 100).round
  end

  def chantier_completion_percentage
    chantier_fields = [:annee_construction, :date_raccordement_electrique, :numero_ean, :autre_bien, :peb]
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
    # Génère un nom basé sur le type et la localisation
    "#{type&.capitalize || 'Bien'} #{commune || 'Sans adresse'}"
  end

  def missing_required_fields
    required_fields.select { |field| self[field].blank? }
  end

  private

  def required_fields
    [:rue, :numero, :code_postal, :commune, :type, :region, :annee_construction, :date_raccordement_electrique, :numero_ean]
  end
end
