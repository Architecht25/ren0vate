# V2 — Lot 6 : garanties scopées par lot comme les documents/devis/réserves
# — un entrepreneur voit les garanties de son propre lot, pas celles des
# autres corps de métier.
class WarrantyPolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    project_owner? || visible_via_lot_scope?
  end

  def create?
    project_owner? || member_with_role?("architect")
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.blank?

      accessible_project_ids = Project.where(user_id: user.id)
                                       .or(Project.where(id: ProjectMember.active.where(user_id: user.id).select(:project_id)))
                                       .select(:id)
      visible_ids = scope.where(project_id: accessible_project_ids).select do |warranty|
        WarrantyPolicy.new(user, warranty).show?
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
