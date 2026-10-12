# V2 — Lot 2 : avenant (cahier des charges §4-5.C). Une proposition d'avenant
# n'a d'effet financier qu'une fois validée explicitement par le
# propriétaire — delta_montant n'est reflété nulle part ailleurs (budget,
# devis) avant #validate_by!.
class ProjectAmendment < ApplicationRecord
  belongs_to :project
  belongs_to :project_quote, optional: true
  belongs_to :requested_by, class_name: "User"
  belongs_to :validated_by, class_name: "User", optional: true

  enum :status, { propose: "propose", valide: "valide", refuse: "refuse" }, default: "propose"

  validates :motif, presence: true
  validates :delta_montant, numericality: true

  def decide!(status:, by:)
    update!(status: status, validated_by: by, validated_at: Time.current)
  end
end
