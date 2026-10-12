# V2 — Lot 4 : tâche de planning (cahier des charges §4-5.D). Version
# simplifiée : une dépendance au plus par tâche (bloquée tant que
# depends_on n'est pas terminée), pas un graphe complet — suffisant pour
# un planning de chantier séquencé par lot, pas un ordonnanceur généraliste.
class ScheduleItem < ApplicationRecord
  belongs_to :project
  belongs_to :lot, optional: true
  belongs_to :depends_on, class_name: "ScheduleItem", optional: true

  has_many :blocked_items, class_name: "ScheduleItem", foreign_key: :depends_on_id, dependent: :nullify, inverse_of: :depends_on

  enum :status, { a_faire: "a_faire", en_cours: "en_cours", termine: "termine" }, default: "a_faire"

  validates :label, presence: true
  validate :lot_belongs_to_project
  validate :depends_on_belongs_to_project
  validate :no_self_dependency

  def blocked?
    depends_on.present? && !depends_on.termine?
  end

  private

  def lot_belongs_to_project
    return if lot.blank?
    errors.add(:lot, "n'appartient pas à ce chantier") if lot.project_id != project_id
  end

  def depends_on_belongs_to_project
    return if depends_on.blank?
    errors.add(:depends_on, "n'appartient pas à ce chantier") if depends_on.project_id != project_id
  end

  def no_self_dependency
    errors.add(:depends_on, "ne peut pas dépendre d'elle-même") if depends_on_id.present? && depends_on_id == id
  end
end
