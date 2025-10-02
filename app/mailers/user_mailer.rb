class UserMailer < Devise::Mailer
  include DeviseUrlHelper

  def confirmation_instructions(record, token, opts = {})
    @token = token
    @resource = record

    # Utiliser la locale préférée de l'utilisateur
    I18n.with_locale(record.preferred_locale || I18n.default_locale) do
      devise_mail(record, :confirmation_instructions, opts)
    end
  end

  def reset_password_instructions(record, token, opts = {})
    @token = token
    @resource = record

    # Utiliser la locale préférée de l'utilisateur
    I18n.with_locale(record.preferred_locale || I18n.default_locale) do
      devise_mail(record, :reset_password_instructions, opts)
    end
  end

  def tracking_email_received(user, request_progress)
    @user = user
    @request_progress = request_progress
    @property = request_progress.request.property

    I18n.with_locale(user.preferred_locale || I18n.default_locale) do
      mail(
        to: user.email,
        subject: "Mise à jour de votre demande de prime - #{@property.address}"
      )
    end
  end

  protected

  def confirmation_url(record, opts = {})
    locale = record.preferred_locale || I18n.default_locale
    Rails.application.routes.url_helpers.user_confirmation_url(
      confirmation_token: @token,
      locale: locale,
      **opts
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
end
