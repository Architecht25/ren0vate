class SupportMailer < ApplicationMailer
  ADMIN_EMAIL = ENV.fetch('ADMIN_EMAIL', 'robin@primes-services.be').freeze

  # Accusé de réception à l'utilisateur
  def ticket_received(user, ticket)
    @user   = user
    @ticket = ticket
    mail(
      to:      user.email,
      subject: "[Ren0vate Support] Votre demande ##{ticket.id} a été reçue"
    )
  end

  # Notification à l'admin — nouveau ticket
  def admin_new_ticket(ticket)
    @ticket = ticket
    @user   = ticket.user
    mail(
      to:      ADMIN_EMAIL,
      subject: "🎫 [Support] Nouveau ticket ##{ticket.id} — #{ticket.user.email}"
    )
  end

  # Notification à l'admin — l'utilisateur a répondu
  def admin_user_replied(ticket, message)
    @ticket  = ticket
    @message = message
    @user    = ticket.user
    mail(
      to:      ADMIN_EMAIL,
      subject: "💬 [Support] Réponse sur ticket ##{ticket.id} — #{ticket.user.email}"
    )
  end

  # Notification à l'utilisateur — l'admin a répondu
  def user_admin_replied(ticket, message)
    @ticket  = ticket
    @message = message
    @user    = ticket.user
    mail(
      to:      @user.email,
      subject: "[Ren0vate Support] Réponse à votre demande ##{ticket.id}"
    )
  end

  # Notification résolution
  def ticket_resolved(ticket)
    @ticket = ticket
    @user   = ticket.user
    mail(
      to:      @user.email,
      subject: "[Ren0vate Support] Votre demande ##{ticket.id} a été résolue"
    )
  end

  # Alerte admin — SLA bientôt dépassé (< 2h restantes)
  def sla_approaching(ticket)
    @ticket = ticket
    @user   = ticket.user
    mail(
      to:      ADMIN_EMAIL,
      subject: "⚠️ [Support SLA] Ticket ##{ticket.id} expire dans ~2h — #{ticket.user.email}"
    )
  end
end
