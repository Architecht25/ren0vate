class NurturingSequenceJob < ApplicationJob
  queue_as :default

  def perform
    send_n14_emails
    send_n30_emails
    send_n60_emails
    Rails.logger.info "[NurturingSequenceJob] Séquence nurturing terminée."
  end

  private

  # Cible : freemium actifs (≥1 projet) inscrits depuis ~14 jours
  def send_n14_emails
    eligible_freemium
      .where(nurturing_n14_sent_at: nil)
      .where('users.created_at BETWEEN ? AND ?', 15.days.ago, 13.days.ago)
      .each do |user|
        UserMailer.nurturing_n14(user).deliver_later
        user.update_column(:nurturing_n14_sent_at, Time.current)
        Rails.logger.info "[NurturingSequenceJob] N+14 envoyé à #{user.email}"
      end
  end

  # Cible : freemium actifs inscrits depuis ~30 jours
  def send_n30_emails
    eligible_freemium
      .where(nurturing_n30_sent_at: nil)
      .where('users.created_at BETWEEN ? AND ?', 31.days.ago, 29.days.ago)
      .each do |user|
        UserMailer.nurturing_n30(user).deliver_later
        user.update_column(:nurturing_n30_sent_at, Time.current)
        Rails.logger.info "[NurturingSequenceJob] N+30 envoyé à #{user.email}"
      end
  end

  # Cible : freemium actifs inscrits depuis ~60 jours
  def send_n60_emails
    eligible_freemium
      .where(nurturing_n60_sent_at: nil)
      .where('users.created_at BETWEEN ? AND ?', 61.days.ago, 59.days.ago)
      .each do |user|
        UserMailer.nurturing_n60(user).deliver_later
        user.update_column(:nurturing_n60_sent_at, Time.current)
        Rails.logger.info "[NurturingSequenceJob] N+60 envoyé à #{user.email}"
      end
  end

  # Freemium = pas d'abonnement actif, au moins 1 projet, propriétaire (pas pro)
  def eligible_freemium
    User
      .where(professional_type: nil)
      .joins(:projects)
      .where.not(
        id: Subscription.active.select(:user_id)
      )
      .distinct
  end
end
