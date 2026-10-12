class Reserve < ApplicationRecord
  belongs_to :project
  belongs_to :plan_document, class_name: 'Document', optional: true
  # V2 — Lot 4 : périmètre de lot (cahier des charges §4), ajouté sur le
  # modèle V1 existant plutôt que recréé — voir la migration.
  belongs_to :lot, optional: true

  has_one_attached :photo

  STATUTS = %w[ouverte en_cours levee].freeze

  validates :description, presence: true
  validates :statut, inclusion: { in: STATUTS }
  validate :lot_belongs_to_project

  scope :ouvertes,  -> { where(statut: 'ouverte') }
  scope :en_cours,  -> { where(statut: 'en_cours') }
  scope :levees,    -> { where(statut: 'levee') }
  scope :actives,   -> { where(statut: %w[ouverte en_cours]) }

  def levee?   = statut == 'levee'
  def ouverte? = statut == 'ouverte'
  def en_cours? = statut == 'en_cours'

  def statut_label
    { 'ouverte' => 'Ouverte', 'en_cours' => 'En cours', 'levee' => 'Levée' }[statut] || statut
  end

  def statut_color
    { 'ouverte' => 'danger', 'en_cours' => 'warning', 'levee' => 'success' }[statut] || 'secondary'
  end

  def statut_icon
    { 'ouverte' => 'bi-exclamation-circle', 'en_cours' => 'bi-clock', 'levee' => 'bi-check-circle-fill' }[statut] || 'bi-circle'
  end

  def has_pin?
    pin_x.present? && pin_y.present?
  end

  private

  def lot_belongs_to_project
    return if lot.blank?
    errors.add(:lot, "n'appartient pas à ce chantier") if lot.project_id != project_id
  end
end
