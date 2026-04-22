# frozen_string_literal: true

class EtatAvancementMailer < ApplicationMailer
  # Envoyé au propriétaire + membres architectes quand l'entrepreneur soumet un état
  def soumission(etat)
    @etat        = etat
    @project     = etat.project
    @entrepreneur = etat.created_by

    recipients = notification_recipients
    return if recipients.empty?

    mail(
      to:      recipients,
      subject: "[Ren0vate] État d'avancement n°#{@etat.numero} soumis — #{@project.nom}"
    )
  end

  # Envoyé à l'entrepreneur quand le bordereau est approuvé
  def approbation(etat)
    @etat        = etat
    @project     = etat.project
    @entrepreneur = etat.created_by

    mail(
      to:      @entrepreneur.email,
      subject: "[Ren0vate] ✅ État d'avancement n°#{@etat.numero} approuvé — #{@project.nom}"
    )
  end

  # Envoyé à l'entrepreneur quand le bordereau est rejeté
  def rejet(etat)
    @etat         = etat
    @project      = etat.project
    @entrepreneur  = etat.created_by
    @commentaire   = etat.commentaire_approbateur

    mail(
      to:      @entrepreneur.email,
      subject: "[Ren0vate] ❌ État d'avancement n°#{@etat.numero} refusé — #{@project.nom}"
    )
  end

  private

  def notification_recipients
    emails = [@project.user.email]  # propriétaire toujours notifié

    architect_members = @project.project_members
                                .joins(:user)
                                .where(role: "architect")
                                .where.not(accepted_at: nil)
    emails += architect_members.map { |m| m.user.email }

    emails.uniq.compact
  end
end
