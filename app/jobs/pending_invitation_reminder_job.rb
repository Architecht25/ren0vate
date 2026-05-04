class PendingInvitationReminderJob < ApplicationJob
  queue_as :default

  # Envoie un rappel aux invités qui n'ont pas accepté leur invitation après 48h.
  # Conditions :
  #   - status = 'pending'
  #   - invite_sent_at < 48h (invitation envoyée il y a au moins 48h)
  #   - reminder_sent_at IS NULL (pas encore relancé)
  #   - invite_expires_at > maintenant (invitation pas encore expirée)
  #   - invited_email présent
  def perform
    Rails.logger.info "Démarrage du job de relance des invitations en attente"

    cutoff_time  = 48.hours.ago
    sent_count   = 0
    errors_count = 0

    members_to_remind = ProjectMember
      .pending
      .where("invite_sent_at <= ?", cutoff_time)
      .where(reminder_sent_at: nil)
      .where("invite_expires_at > ? OR invite_expires_at IS NULL", Time.current)
      .where.not(invited_email: [nil, ""])
      .includes(project: [:user, :property])

    Rails.logger.info "#{members_to_remind.count} invitation(s) éligible(s) au rappel"

    members_to_remind.each do |member|
      invited_by = member.project.user
      ProjectMailer.invitation_reminder(member, invited_by).deliver_later
      member.update_column(:reminder_sent_at, Time.current)
      sent_count += 1
    rescue => e
      errors_count += 1
      Rails.logger.error "Erreur rappel invitation member##{member.id}: #{e.message}"
    end

    Rails.logger.info "Rappels envoyés : #{sent_count}, erreurs : #{errors_count}"
  end
end
