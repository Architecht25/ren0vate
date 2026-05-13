class UserMailer < Devise::Mailer
  default from: ENV.fetch('DEVISE_MAILER_SENDER', 'no-reply@ren0vate.be')

  def confirmation_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @email = record.email

    # Utiliser la locale préférée de l'utilisateur
    I18n.with_locale(record.preferred_locale || I18n.default_locale) do
      opts[:subject] = t('devise.mailer.confirmation_instructions.subject')
      super
    end
  end

  def reset_password_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @email = record.email

    # Utiliser la locale préférée de l'utilisateur
    I18n.with_locale(record.preferred_locale || I18n.default_locale) do
      opts[:subject] = t('devise.mailer.reset_password_instructions.subject')
      super
    end
  end

  def welcome_premium(user, tier)
    @user = user
    @tier = tier
    @tier_name = Subscription.new(tier: tier).tier_name

    mail(
      to: user.email,
      subject: "🎉 Bienvenue sur Ren0vate #{@tier_name} !"
    )
  end

  def welcome_trial(user, tier)
    @user = user
    @tier = tier
    @tier_name = Subscription.new(tier: tier).tier_name

    mail(
      to: user.email,
      subject: "🚀 Votre essai gratuit Ren0vate #{@tier_name} commence !"
    )
  end

  def trial_ending_soon(user, tier, days_remaining)
    @user = user
    @tier = tier
    @tier_name = Subscription.new(tier: tier).tier_name
    @days_remaining = days_remaining

    mail(
      to: user.email,
      subject: "⏳ Votre essai Ren0vate #{@tier_name} se termine dans #{days_remaining} jour#{'s' if days_remaining > 1}"
    )
  end

  def payment_failed(user)
    @user = user

    mail(
      to: user.email,
      subject: "⚠️ Problème de paiement sur votre abonnement Ren0vate"
    )
  end

  def tracking_email_received(user, request_progress)
    @user = user
    @request_progress = request_progress
    @prime = request_progress.prime

    I18n.with_locale(user.preferred_locale || I18n.default_locale) do
      mail(
        to: user.email,
        subject: "📧 Nouvelle réponse administrative - #{@prime&.titre || 'Votre demande'}"
      )
    end
  end

  # --- Séquence onboarding post-inscription ---

  def onboarding_j1(user)
    @user = user
    mail(
      to:      user.email,
      subject: "🏠 Créez votre premier projet de rénovation sur Ren0vate"
    )
  end

  def onboarding_j3(user)
    @user = user
    mail(
      to:      user.email,
      subject: "👷 Invitez votre architecte ou entrepreneur sur Ren0vate"
    )
  end

  def onboarding_j7(user)
    @user = user
    mail(
      to:      user.email,
      subject: "💶 Découvrez les primes disponibles pour vos travaux"
    )
  end
end
