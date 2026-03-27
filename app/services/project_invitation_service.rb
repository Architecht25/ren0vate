class ProjectInvitationService
  class InvitationError < StandardError; end

  def invite(project:, invited_by:, email:, role:)
    raise InvitationError, "Rôle invalide" unless ProjectMember::ROLES.include?(role)
    raise InvitationError, "Seul le propriétaire peut inviter des pros" unless project.user_id == invited_by.id

    email = email.strip.downcase

    # Trouver ou créer un compte minimal
    user = User.find_by(email: email)

    if user.nil?
      temporary_password = SecureRandom.hex(16)
      user = User.new(
        email:      email,
        password:   temporary_password,
        first_name: "",
        last_name:  ""
      )
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
      user.save!
    end

    # Vérifier qu'il n'est pas déjà membre actif
    existing = project.project_members.find_by(user: user)
    if existing&.active?
      raise InvitationError, "#{email} est déjà membre actif de ce projet"
    end

    # Supprimer un éventuel membre pending expiré pour réinviter
    existing.destroy if existing&.expired?

    member = project.project_members.create!(
      user:            user,
      role:            role,
      invited_email:   email,
      invite_sent_at:  Time.current
    )

    ProjectMailer.invitation(member, invited_by).deliver_later
    member
  rescue ActiveRecord::RecordNotUnique
    raise InvitationError, "#{email} a déjà été invité sur ce projet"
  end
end
