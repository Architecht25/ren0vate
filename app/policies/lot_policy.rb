# V2 — Lot 0 : un entrepreneur ne voit que les lots de son périmètre (cahier
# des charges V2 §3 : "Son lot + documents partagés avec lui"), l'architecte
# et le propriétaire voient tous les lots. La gestion des lots eux-mêmes
# (création/renommage) reste propriétaire uniquement à ce stade — étendre à
# l'architecte est une décision produit non tranchée, voir
# docs/QUESTIONS_OUVERTES.md si le besoin apparaît en Lot 1.
class LotPolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    project_owner? || (active_membership.present? && active_membership.can_access_lot?(record))
  end

  def create?
    project_owner?
  end

  def update?
    project_owner?
  end

  def destroy?
    project_owner?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.blank?

      scope.where(project: owned_project_ids).or(scope.where(project: member_project_ids_with_full_scope))
           .or(scope.where(id: explicitly_scoped_lot_ids))
    end

    private

    def owned_project_ids
      Project.where(user_id: user.id).select(:id)
    end

    def member_project_ids_with_full_scope
      ProjectMember.active.where(user_id: user.id)
                    .where.missing(:project_member_lots)
                    .select(:project_id)
    end

    def explicitly_scoped_lot_ids
      ProjectMemberLot.joins(:project_member)
                       .where(project_members: { user_id: user.id, status: "active" })
                       .select(:lot_id)
    end
  end

  private

  def project
    record.project
  end
end
