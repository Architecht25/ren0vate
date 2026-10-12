# V2 — Lot 6 : visible de tout membre actif (c'est une information
# administrative sur l'ensemble du chantier, pas scopée par lot — contrairement
# aux documents/devis/réserves). Gestion réservée au propriétaire et à
# l'architecte, comme pour le planning (§3 : rôle de pilotage).
class ComplianceItemPolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    project_owner? || active_member?
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

      scope.where(project: Project.where(user_id: user.id))
           .or(scope.where(project: ProjectMember.active.where(user_id: user.id).select(:project_id)))
    end
  end

  private

  def project
    record.project
  end
end
