class ProjectMailer < ApplicationMailer
  def invitation(member, invited_by)
    @member      = member
    @project     = member.project
    @property    = @project.property
    @invited_by  = invited_by
    @role_label  = member.role_label
    @accept_url  = invitation_url(token: member.invite_token)
    @expires_at  = member.invite_expires_at

    mail(
      to:      member.invited_email,
      subject: "#{invited_by.full_name} vous invite sur le projet « #{@project.name} » — Ren0vate"
    )
  end

  def member_joined(member)
    @member     = member
    @project    = member.project
    @owner      = @project.user
    @role_label = member.role_label

    mail(
      to:      @owner.email,
      subject: "#{member.user.full_name} a rejoint votre projet « #{@project.name} » — Ren0vate"
    )
  end

  # Notifie le pro (architecte/entrepreneur) qu'un client qui a utilisé son lien
  # de parrainage vient de créer un projet — accès en attente de validation client.
  def pro_referral_pending(member, client)
    @member  = member
    @project = member.project
    @client  = client
    @pro     = member.user

    mail(
      to:      @pro.email,
      subject: "#{@client.full_name.presence || @client.email} a créé un projet sur Ren0vate — en attente de votre accès"
    )
  end
end
