# V2 — Lot 4 : tout membre actif peut consigner une observation (dépôt
# photo terrain, §11 "mobile first"), scopée par lot comme les autres
# ressources. Seul son auteur ou le propriétaire peut la modifier/supprimer
# — une entrée de journal engage celui qui l'a écrite.
class SiteLogEntryPolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    project_owner? || visible_via_lot_scope?
  end

  def create?
    project_owner? || active_member?
  end

  def update?
    project_owner? || author?
  end

  def destroy?
    project_owner? || author?
  end

  class Scope < Scope
    def resolve
      return scope.none if user.blank?

      accessible_project_ids = Project.where(user_id: user.id)
                                       .or(Project.where(id: ProjectMember.active.where(user_id: user.id).select(:project_id)))
                                       .select(:id)
      visible_ids = scope.where(project_id: accessible_project_ids).select do |entry|
        SiteLogEntryPolicy.new(user, entry).show?
      end.map(&:id)

      scope.where(id: visible_ids)
    end
  end

  private

  def project
    record.project
  end

  def author?
    user.present? && record.author_id == user.id
  end

  def visible_via_lot_scope?
    return false unless active_member?
    return true if record.lot.blank?
    active_membership.can_access_lot?(record.lot)
  end
end
