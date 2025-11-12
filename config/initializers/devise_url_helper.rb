module DeviseUrlHelper
  def confirmation_url(resource, opts = {})
    locale = resource.preferred_locale || I18n.default_locale

    # Utiliser directement les routes Devise sans locale car elles sont définies en dehors du scope
    Rails.application.routes.url_helpers.user_confirmation_url(opts)
  end

  def reset_password_url(resource, opts = {})
    locale = resource.preferred_locale || I18n.default_locale

    # Utiliser directement les routes Devise sans locale
    Rails.application.routes.url_helpers.edit_user_password_url(opts)
  end
end

# Inclure dans ActionMailer
ActionMailer::Base.include DeviseUrlHelper
