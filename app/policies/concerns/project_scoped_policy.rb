# V2 — Lot 0 : partagé par toutes les policies dont le record appartient à un
# Project (directement ou via #project). Centralise la question "cet
# utilisateur est-il propriétaire / membre actif / membre actif scopé à ce
# lot de ce chantier ?", posée identiquement par ProjectPolicy, LotPolicy et
# ProjectMemberPolicy — la matrice rôle x action x visibilité du cahier des
# charges V2 §3 part toujours de cette même question.
module ProjectScopedPolicy
  private

  def project_owner?
    user.present? && project.present? && project.user_id == user.id
  end

  def active_membership
    return nil if user.blank? || project.blank?
    @active_membership ||= project.project_members.active.find_by(user_id: user.id)
  end

  def active_member?
    active_membership.present?
  end

  def member_with_role?(*roles)
    active_membership.present? && roles.map(&:to_s).include?(active_membership.role)
  end
end
