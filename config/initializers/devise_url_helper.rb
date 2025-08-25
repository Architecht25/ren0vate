module DeviseUrlHelper
  def confirmation_url(resource, opts = {})
    locale = resource.preferred_locale || I18n.default_locale
    Rails.application.routes.url_helpers.user_confirmation_url(
      opts.merge(locale: locale)
    )
  end

  def reset_password_url(resource, opts = {})
    locale = resource.preferred_locale || I18n.default_locale
    Rails.application.routes.url_helpers.edit_user_password_url(
      opts.merge(locale: locale)
    )
  end
end

# Inclure dans ActionMailer
ActionMailer::Base.include DeviseUrlHelper
