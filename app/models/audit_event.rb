# V2 — Lot 0 : journal d'audit générique, append-only (cahier des charges V2
# §6 : "inaltérable"). Jamais modifié ni supprimé après création — toute
# tentative lève une erreur plutôt que d'échouer silencieusement.
class AuditEvent < ApplicationRecord
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :auditable, polymorphic: true
  belongs_to :project, optional: true

  validates :action, presence: true

  before_update { raise ActiveRecord::ReadOnlyRecord, "AuditEvent est append-only : aucune modification après création" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "AuditEvent est append-only : aucune suppression" }

  def self.record!(action:, auditable:, actor: nil, project: nil, event_data: {}, ip_address: nil)
    create!(
      action: action,
      auditable: auditable,
      actor: actor,
      project: project || infer_project(auditable),
      event_data: event_data,
      ip_address: ip_address
    )
  end

  def self.infer_project(auditable)
    return auditable if auditable.is_a?(Project)
    auditable.project if auditable.respond_to?(:project)
  end
  private_class_method :infer_project
end
