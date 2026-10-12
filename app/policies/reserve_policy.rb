# V2 — Lot 4 : réserves de réception, scopées par lot comme les documents et
# devis (cahier des charges §3). Un entrepreneur ne voit/modifie que les
# réserves de son périmètre de lots (ou toutes, s'il n'a pas de périmètre
# restreint — comportement V1 préservé pour les project_members sans
# ProjectMemberLot, voir ProjectMember#scoped_to_all_lots?).
class ReservePolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    project_owner? || visible_via_lot_scope?
  end

  def create?
    project_owner? || active_member?
  end

  def update?
    project_owner? || visible_via_lot_scope?
  end

  def destroy?
    project_owner?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.blank?

      accessible_project_ids = Project.where(user_id: user.id)
                                       .or(Project.where(id: ProjectMember.active.where(user_id: user.id).select(:project_id)))
                                       .select(:id)
      visible_ids = scope.where(project_id: accessible_project_ids).select do |reserve|
        ReservePolicy.new(user, reserve).show?
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
