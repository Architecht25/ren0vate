# Surveille activement les RequestProgress en attente : notifie l'utilisateur
# quand le délai administratif approche, et fait expirer les compléments de
# dossier dont la deadline est dépassée. Sans ce job, ces informations
# (date_limite_reponse, jours_restants, statut_delai, handle_complement_expiry!)
# n'étaient calculées que si l'utilisateur ouvrait lui-même la page de suivi.
class RequestProgressDeadlineJob < ApplicationJob
  queue_as :default

  def perform
    notify_approaching_deadlines
    expire_overdue_complements
  end

  private

  def notify_approaching_deadlines
    notified = 0

    RequestProgress.en_attente.find_each do |request_progress|
      next unless request_progress.date_soumission
      next unless request_progress.statut_delai == :urgent

      user = request_progress.property&.user
      next unless user
      next if already_notified_recently?(user, request_progress)

      Notification.create_deadline_proche(
        user,
        request_progress.date_limite_reponse,
        "votre demande de prime #{request_progress.request&.region&.capitalize} (suivi ##{request_progress.id})"
      )
      notified += 1
    end

    Rails.logger.info "[RequestProgressDeadlineJob] #{notified} notification(s) de délai envoyée(s)"
  end

  def already_notified_recently?(user, request_progress)
    Notification.where(user: user, type: :deadline_proche)
                .where("message LIKE ?", "%suivi ##{request_progress.id}%")
                .where("created_at > ?", 25.hours.ago)
                .exists?
  end

  def expire_overdue_complements
    expired = 0

    RequestProgress.joins(:complement_requests)
                    .merge(ComplementRequest.overdue)
                    .distinct
                    .find_each do |request_progress|
      request_progress.handle_complement_expiry!
      expired += 1
    end

    Rails.logger.info "[RequestProgressDeadlineJob] #{expired} dossier(s) avec complément(s) expiré(s) traité(s)"
  end
end
