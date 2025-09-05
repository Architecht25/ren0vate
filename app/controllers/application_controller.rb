class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Protection CSRF
  protect_from_forgery with: :exception

  # Configuration I18n pour la Belgique
  before_action :set_locale
  around_action :switch_locale

  # Headers de sécurité
  before_action :set_security_headers

  private

  def set_locale
    # 1. Paramètre URL (?locale=nl)
    if params[:locale].present? && I18n.available_locales.include?(params[:locale].to_sym)
      session[:locale] = params[:locale]
      I18n.locale = params[:locale]

    # 2. Session utilisateur
    elsif session[:locale].present? && I18n.available_locales.include?(session[:locale].to_sym)
      I18n.locale = session[:locale]

    # 3. Préférence utilisateur connecté
    elsif user_signed_in? && current_user.preferred_locale.present?
      I18n.locale = current_user.preferred_locale
      session[:locale] = current_user.preferred_locale

    # 4. Détection par région de la propriété
    elsif user_signed_in? && current_user.properties.any?
      locale = detect_locale_from_region
      I18n.locale = locale if locale

    # 5. En-têtes HTTP Accept-Language avec la gem
    elsif respond_to?(:http_accept_language) && http_accept_language.present?
      I18n.locale = http_accept_language.compatible_language_from(I18n.available_locales) || I18n.default_locale

    # 6. Défaut
    else
      I18n.locale = I18n.default_locale
    end

    Rails.logger.debug "🌍 Locale set to: #{I18n.locale}"
  end

  def switch_locale(&action)
    locale = I18n.locale || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def detect_locale_from_region
    return nil unless user_signed_in?

    # Prendre la région de la dernière propriété modifiée
    last_property = current_user.properties.order(:updated_at).last
    return nil unless last_property&.region

    case last_property.region.downcase
    when 'flandre', 'vlaanderen'
      :nl
    when 'wallonie', 'wallonië'
      :fr
    when 'bruxelles', 'brussel', 'brussels'
      # Bruxelles est bilingue, garder le choix utilisateur ou défaut
      session[:locale]&.to_sym || :fr
    else
      nil
    end
  end

  def default_url_options
    { locale: I18n.locale }
  end

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def set_security_headers
    # X-Frame-Options : Protection contre le clickjacking
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'

    # X-Content-Type-Options : Empêcher le MIME type sniffing
    response.headers['X-Content-Type-Options'] = 'nosniff'

    # X-XSS-Protection : Protection XSS pour les anciens navigateurs
    response.headers['X-XSS-Protection'] = '1; mode=block'

    # Referrer-Policy : Contrôler les informations de référent
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'

    # Feature-Policy / Permissions-Policy : Contrôler les APIs du navigateur
    response.headers['Permissions-Policy'] = [
      'camera=(), microphone=(), geolocation=(self)',
      'payment=(), usb=(), magnetometer=(), gyroscope=()',
      'accelerometer=(), ambient-light-sensor=(), autoplay=()',
      'encrypted-media=(), fullscreen=(self), picture-in-picture=()'
    ].join(', ')

    if Rails.env.production?
      # Strict-Transport-Security : Forcer HTTPS
      response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload'

      # Expect-CT : Certificate Transparency
      response.headers['Expect-CT'] = 'max-age=86400, enforce'
    end
  end

  protected

  def configure_permitted_parameters
    # Pour l'inscription
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])

    # Pour la mise à jour du compte
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end
end
