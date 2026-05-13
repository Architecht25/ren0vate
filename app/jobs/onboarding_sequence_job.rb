class OnboardingSequenceJob < ApplicationJob
  queue_as :default

  def perform
    send_j1_emails
    send_j3_emails
    send_j7_emails
    Rails.logger.info "[OnboardingSequenceJob] Séquence emails terminée."
  end

  private

  # J+1 : "Créez votre premier projet" — uniquement pour les propriétaires sans projet
  def send_j1_emails
    users = User.where(professional_type: nil)
                .where(onboarding_j1_sent_at: nil)
                .where('created_at BETWEEN ? AND ?', 25.hours.ago, 23.hours.ago)

    users.each do |user|
      next if user.properties.any? && user.properties.flat_map(&:projects).any?

      UserMailer.onboarding_j1(user).deliver_later
      user.update_column(:onboarding_j1_sent_at, Time.current)
      Rails.logger.info "[OnboardingSequenceJob] J+1 envoyé à #{user.email}"
    end
  end

  # J+3 : "Invitez votre architecte / entrepreneur"
  def send_j3_emails
    users = User.where(professional_type: nil)
                .where(onboarding_j3_sent_at: nil)
                .where('created_at BETWEEN ? AND ?', 73.hours.ago, 71.hours.ago)

    users.each do |user|
      UserMailer.onboarding_j3(user).deliver_later
      user.update_column(:onboarding_j3_sent_at, Time.current)
      Rails.logger.info "[OnboardingSequenceJob] J+3 envoyé à #{user.email}"
    end
  end

  # J+7 : "Avez-vous vu nos simulateurs de primes ?"
  def send_j7_emails
    users = User.where(professional_type: nil)
                .where(onboarding_j7_sent_at: nil)
                .where('created_at BETWEEN ? AND ?', 169.hours.ago, 167.hours.ago)

    users.each do |user|
      UserMailer.onboarding_j7(user).deliver_later
      user.update_column(:onboarding_j7_sent_at, Time.current)
      Rails.logger.info "[OnboardingSequenceJob] J+7 envoyé à #{user.email}"
    end
  end
end
