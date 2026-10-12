# V2 — Lot 4 : messagerie par lot (cahier des charges §5.D), scopée comme
# documents/devis/réserves/journal.
class MessageThreadPolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    project_owner? || visible_via_lot_scope?
  end

  def create?
    project_owner? || active_member?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.blank?

      accessible_project_ids = Project.where(user_id: user.id)
                                       .or(Project.where(id: ProjectMember.active.where(user_id: user.id).select(:project_id)))
                                       .select(:id)
      visible_ids = scope.where(project_id: accessible_project_ids).select do |thread|
        MessageThreadPolicy.new(user, thread).show?
      end.map(&:id)

      scope.where(id: visible_ids)
    end
  end

  private

  def project
    record.project
  end

  def visible_via_lot_scope?
    return false unless active_member?
    return true if record.lot.blank?
    active_membership.can_access_lot?(record.lot)
  end
end
