class DormantProjectAlertJob < ApplicationJob
  queue_as :default

  # Déclencheurs (événements projet, jamais surveillance de l'inactivité) :
  #
  #   1. PRIME_EXPIRY — une facture avec date_limite_prime < 30 jours
  #      sur un projet dont updated_at < 10 jours
  #   2. RECEPTION_PENDING — date_fin passée depuis > 7 jours sans pv_reception
  #      sur un projet dont updated_at < 10 jours
  #
  # Garde-fou : 1 seul email de ce type par user tous les 14 jours minimum
  # (last_project_alert_at sur User).
  # Jamais envoyé aux professionnels (professional_type présent) — ils ont leur propre flow.

  INACTIVITY_THRESHOLD  = 10.days  # projet non modifié depuis X jours
  PRIME_WINDOW_DAYS     = 30       # prime expirant dans moins de X jours
  RECEPTION_DELAY_DAYS  = 7        # date_fin dépassée depuis X jours sans réception
  ALERT_COOLDOWN        = 14.days  # minimum entre deux emails de ce type

  def perform
    Rails.logger.info "Démarrage DormantProjectAlertJob"
    sent = 0
    skipped = 0

    eligible_users.each do |user|
      alerts = collect_alerts_for(user)
      next if alerts.empty?

      ProjectMailer.dormant_project_alert(user, alerts).deliver_later
      user.update_column(:last_project_alert_at, Time.current)
      sent += 1
    rescue => e
      skipped += 1
      Rails.logger.error "DormantProjectAlertJob — erreur user##{user.id}: #{e.message}"
    end

    Rails.logger.info "DormantProjectAlertJob terminé — envoyés: #{sent}, ignorés: #{skipped}"
  end

  private

  def eligible_users
    cooldown_cutoff = ALERT_COOLDOWN.ago
    User
      .where(professional_type: nil)
      .where("last_project_alert_at IS NULL OR last_project_alert_at < ?", cooldown_cutoff)
      .joins(:projects)
      .distinct
  end

  def collect_alerts_for(user)
    alerts = []
    inactivity_cutoff = INACTIVITY_THRESHOLD.ago

    user.projects.each do |project|
      # Ignorer les projets actifs (modifiés récemment)
      next if project.updated_at > inactivity_cutoff

      # Déclencheur 1 — prime bientôt expirée
      prime_alert = check_prime_expiry(project)
      alerts << prime_alert if prime_alert

      # Déclencheur 2 — travaux terminés sans PV de réception
      reception_alert = check_reception_pending(project)
      alerts << reception_alert if reception_alert
    end

    alerts
  end

  def check_prime_expiry(project)
    upcoming_deadline = project.factures
      .where("date_limite_prime IS NOT NULL")
      .where("date_limite_prime <= ? AND date_limite_prime >= ?",
             PRIME_WINDOW_DAYS.days.from_now.to_date,
             Date.current)
      .order(:date_limite_prime)
      .first

    return nil unless upcoming_deadline

    days_left = (upcoming_deadline.date_limite_prime - Date.current).to_i
    {
      type:    :prime_expiry,
      project: project,
      detail:  "Le délai de prime pour une facture expire dans #{days_left} jour#{'s' if days_left > 1} " \
               "(#{upcoming_deadline.date_limite_prime.strftime('%d/%m/%Y')}). " \
               "Déposez votre demande avant cette date pour ne pas perdre la prime."
    }
  end

  def check_reception_pending(project)
    return nil unless project.date_fin.present?
    return nil if project.date_fin > RECEPTION_DELAY_DAYS.days.ago.to_date
    return nil if project.pv_reception.present?

    days_overdue = (Date.current - project.date_fin).to_i
    {
      type:    :reception_pending,
      project: project,
      detail:  "Les travaux étaient prévus terminés le #{project.date_fin.strftime('%d/%m/%Y')} " \
               "(il y a #{days_overdue} jour#{'s' if days_overdue > 1}). " \
               "Le PV de réception est manquant — étape nécessaire pour clôturer le dossier et activer les garanties."
    }
  end
end
