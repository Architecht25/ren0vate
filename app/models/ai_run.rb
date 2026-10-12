# V2 — Lot 2 : journal de tout appel IA (cahier des charges §8). "L'IA ne
# décide jamais : elle propose" — validated_by/validated_at enregistrent la
# confirmation humaine explicite quand un contrôleur applique une
# suggestion, ce n'est jamais automatique.
class AiRun < ApplicationRecord
  belongs_to :project
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :validated_by, class_name: "User", optional: true

  STATUSES = %w[pending success error].freeze

  validates :function, presence: true
  validates :model, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :for_current_month, -> { where(created_at: Time.current.all_month) }

  def self.monthly_cost_cents(project)
    for_current_month.where(project: project).sum(:estimated_cost_cents)
  end

  def validated?
    validated_at.present?
  end

  def mark_validated!(by:)
    update!(validated_by: by, validated_at: Time.current)
  end
end
