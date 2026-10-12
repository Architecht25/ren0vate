# V2 — Lot 4 : journal de chantier (cahier des charges §5.D). Plusieurs
# photos possibles par entrée via has_many_attached — mobile-first (§11 :
# "dépôt de photos... terrain"), une entrée = un passage/une observation,
# pas un document formel (pas de versionnage comme ProjectDocument).
class SiteLogEntry < ApplicationRecord
  belongs_to :project
  belongs_to :lot, optional: true
  belongs_to :author, class_name: "User"

  has_many_attached :photos

  validates :body, presence: true
  validates :observed_at, presence: true
  validate :lot_belongs_to_project

  before_validation :set_default_observed_at, on: :create

  scope :chronological, -> { order(observed_at: :desc) }

  def geolocated?
    latitude.present? && longitude.present?
  end

  private

  def set_default_observed_at
    self.observed_at ||= Time.current
  end

  def lot_belongs_to_project
    return if lot.blank?
    errors.add(:lot, "n'appartient pas à ce chantier") if lot.project_id != project_id
  end
end
