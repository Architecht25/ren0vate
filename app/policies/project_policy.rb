# V2 — Lot 0 : matrice rôle x action pour Project (cahier des charges V2 §3).
# Visibilité au niveau Lot (ex : un entrepreneur restreint à son lot) est
# tranchée par LotPolicy, pas ici — show? ouvre l'accès au projet à tout
# membre actif, quel que soit son périmètre de lots.
class ProjectPolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    project_owner? || active_member?
  end

  def create?
    user.present?
  end

  def update?
    project_owner?
  end

  def destroy?
    project_owner?
  end

  def manage_members?
    project_owner?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.blank?

      scope.where(user_id: user.id)
           .or(scope.where(id: ProjectMember.active.where(user_id: user.id).select(:project_id)))
    end
  end

  private

  def project
    record
  end
end
