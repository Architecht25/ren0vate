# V2 — Lot 1 : la règle de sécurité centrale de la base documentaire (cahier
# des charges §3 : "Chaque document a... une visibilité... Les policies sont
# testées exhaustivement (matrice rôle × action × visibilité)"). Le
# déposant et le propriétaire voient toujours leur propre document, quelle
# que soit la visibilité déclarée — une visibilité "private" cache le
# document aux AUTRES, pas à son auteur.
class ProjectDocumentPolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    project_owner? || uploader? || visible_via_role?
  end

  def create?
    project_owner? || active_member?
  end

  def add_version?
    show?
  end

  def update?
    project_owner? || uploader?
  end

  def destroy?
    project_owner? || uploader?
  end

  def comment?
    show?
  end

  # Valider/refuser/demander une correction (cahier des charges §3 :
  # l'architecte "vérifie les devis, émet les PV, lève les réserves").
  # L'entrepreneur ne revoit jamais un document, y compris le sien.
  def review?
    project_owner? || member_with_role?("architect")
  end

  class Scope < Scope
    # Filtrage en mémoire plutôt qu'en SQL : le volume par chantier reste
    # faible en Lot 1 (pas encore d'ingestion en masse) et la logique de
    # visibilité est identique à ProjectDocumentPolicy#show? — dupliquer
    # cette logique en SQL aurait un coût de maintenance plus élevé que son
    # coût en performance ici. À revoir si le volume grossit (Lot 2+).
    def resolve
      return scope.none if user.blank?

      accessible_project_ids = Project.where(user_id: user.id)
                                       .or(Project.where(id: ProjectMember.active.where(user_id: user.id).select(:project_id)))
                                       .select(:id)
      visible_ids = scope.where(project_id: accessible_project_ids).select do |document|
        ProjectDocumentPolicy.new(user, document).show?
      end.map(&:id)

      scope.where(id: visible_ids)
    end
  end

  private

  def project
    record.project
  end

  def uploader?
    user.present? && record.uploaded_by_id == user.id
  end

  def visible_via_role?
    return false unless active_member?

    case record.visibility
    when "all" then true
    when "lot" then record.lot.present? && active_membership.can_access_lot?(record.lot)
    when "custom" then record.shares.exists?(user_id: user.id)
    else false # "private" (private_doc)
    end
  end
end
