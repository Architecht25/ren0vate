# V2 — Lot 0 : seul le propriétaire du chantier invite, modifie ou retire un
# intervenant (cahier des charges V2 §3 : "Le propriétaire reste maître du
# dossier : il peut retirer ou limiter un accès à tout moment"). Un
# intervenant peut voir sa propre ligne d'adhésion (ex: pour consulter son
# propre périmètre de lots) mais pas celle des autres.
class ProjectMemberPolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    project_owner? || record.user_id == user&.id
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

      scope.where(project: Project.where(user_id: user.id)).or(scope.where(user_id: user.id))
    end
  end

  private

  def project
    record.project
  end
end
