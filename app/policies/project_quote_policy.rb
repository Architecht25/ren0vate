# V2 — Lot 2 : un entrepreneur dépose et voit les devis de son propre
# périmètre de lots ; seul le propriétaire choisit/valide un devis (cahier
# des charges §5.C : "Comparateur de devis par lot" + §3 "Le propriétaire
# reste maître du dossier").
class ProjectQuotePolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    project_owner? || submitter? || visible_via_lot_scope?
  end

  def create?
    project_owner? || active_member?
  end

  def update?
    project_owner? || (submitter? && record.brouillon?)
  end

  def destroy?
    update?
  end

  # Marquer un devis accepté/refusé — décision du propriétaire uniquement.
  def decide?
    project_owner?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.blank?

      accessible_project_ids = Project.where(user_id: user.id)
                                       .or(Project.where(id: ProjectMember.active.where(user_id: user.id).select(:project_id)))
                                       .select(:id)
      visible_ids = scope.where(project_id: accessible_project_ids).select do |quote|
        ProjectQuotePolicy.new(user, quote).show?
      end.map(&:id)

      scope.where(id: visible_ids)
    end
  end

  private

  def project
    record.project
  end

  def submitter?
    user.present? && record.submitted_by_id == user.id
  end

  def visible_via_lot_scope?
    return false unless active_member?
    return true if record.lot.blank?
    active_membership.can_access_lot?(record.lot)
  end
end
