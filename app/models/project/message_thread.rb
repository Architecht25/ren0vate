# V2 — Lot 4 : messagerie par lot (cahier des charges §4-5.D). Nommé
# MessageThread, pas Thread — voir le commentaire de la migration (`Thread`
# est une classe native Ruby, à ne jamais masquer avec un modèle).
class MessageThread < ApplicationRecord
  belongs_to :project
  belongs_to :lot, optional: true

  has_many :messages, dependent: :destroy

  validates :title, presence: true
  validate :lot_belongs_to_project

  private

  def lot_belongs_to_project
    return if lot.blank?
    errors.add(:lot, "n'appartient pas à ce chantier") if lot.project_id != project_id
  end
end
