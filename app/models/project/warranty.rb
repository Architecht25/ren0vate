# V2 — Lot 6 : garantie avec rappel d'échéance (cahier des charges §4-5.E :
# "Warranty (type, début, échéance, rappels)"). Pas de système de rappel
# programmé dans ce lot (pas de job dédié) — #expiring_soon?/#expired?
# permettent d'afficher un signal dans l'UI (coffre-fort, dashboard),
# l'envoi d'email/notification proactif est un travail distinct non
# commencé (nécessiterait un job périodique, cf. CLAUDE.md sur les
# jobs déjà existants pour ce type de rappel en V1 — FactureAlertJob).
class Warranty < ApplicationRecord
  belongs_to :project
  belongs_to :lot, optional: true
  belongs_to :project_document, optional: true

  validates :label, presence: true
  validates :start_date, :end_date, presence: true
  validate :end_after_start

  scope :active, -> { where("end_date >= ?", Date.current) }
  scope :expired, -> { where("end_date < ?", Date.current) }

  def expired?
    end_date < Date.current
  end

  def expiring_soon?(within: 90.days)
    !expired? && end_date <= Date.current + within
  end

  private

  def end_after_start
    return if start_date.blank? || end_date.blank?
    errors.add(:end_date, "doit être postérieure à la date de début") if end_date <= start_date
  end
end
