# V2 — Lot 2 : tout membre actif peut proposer un avenant, seul le
# propriétaire le valide ou le refuse (cahier des charges §3 : "validation
# propriétaire tracée").
class ProjectAmendmentPolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    project_owner? || active_member?
  end

  def create?
    project_owner? || active_member?
  end

  def decide?
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
