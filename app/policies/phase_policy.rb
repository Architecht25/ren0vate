# V2 — toute phase est visible par tout membre actif du chantier (contrairement
# au lot, la phase n'a pas de périmètre restreint par intervenant — cahier des
# charges §4 : les phases structurent le chantier dans son ensemble, pas un
# accès). Gestion (création/modification/suppression) réservée au propriétaire,
# comme pour Lot — voir LotPolicy pour la même décision non tranchée sur une
# extension éventuelle à l'architecte.
class PhasePolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    project_owner? || active_member?
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

      scope.where(project: Project.where(user_id: user.id))
           .or(scope.where(project: ProjectMember.active.where(user_id: user.id).select(:project_id)))
    end
  end

  private

  def project
    record.project
  end
end
