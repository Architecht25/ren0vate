# V2 — Lot 4 : planning, scopé par lot comme les autres ressources
# d'exécution. Gestion (créer/modifier des tâches) réservée au propriétaire
# et à l'architecte — un entrepreneur suit son planning, il ne le redéfinit
# pas (cahier des charges §3 : l'architecte "vérifie les devis... lève les
# réserves", rôle de pilotage ; l'entrepreneur dépose/répond).
class ScheduleItemPolicy < ApplicationPolicy
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
      visible_ids = scope.where(project_id: accessible_project_ids).select do |item|
        ScheduleItemPolicy.new(user, item).show?
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
