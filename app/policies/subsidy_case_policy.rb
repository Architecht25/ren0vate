# V2 — Lot 3 : mode simulation (cahier des charges §9) — public, sans
# compte ; mode dossier rattaché à un chantier, visible par le propriétaire
# et les membres actifs.
class SubsidyCasePolicy < ApplicationPolicy
  include ProjectScopedPolicy

  def show?
    return anonymous_or_own? if record.project.blank?
    project_owner? || active_member?
  end

  def create?
    true # la simulation est volontairement publique (cahier des charges §9)
  end

  private

  def project
    record.project
  end

  def anonymous_or_own?
    record.user_id.blank? || record.user_id == user&.id
  end
end
