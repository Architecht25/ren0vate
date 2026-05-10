class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Protection CSRF
  protect_from_forgery with: :exception

  # Gestion globale des erreurs d'encodage
  rescue_from ActionController::BadRequest do |exception|
    if exception.message.include?('Invalid encoding')
      Rails.logger.warn "⚠️ Erreur d'encodage interceptée: #{exception.message}"
      render json: {
        error: 'Problème d\'encodage détecté',
        message: 'Veuillez reformuler votre message avec des caractères standard',
        status: 400
      }, status: 400
    else
      raise exception
    end
  end

  # Include Cloudinary helper for static images
  include CloudinaryHelper

  # Configuration I18n pour la Belgique
  before_action :set_locale
  around_action :switch_locale

  # Sentry — identifier l'utilisateur connecté dans les rapports d'erreur
  before_action :set_sentry_user

  # Headers de sécurité
  before_action :set_security_headers

  private

  def set_sentry_user
    return unless user_signed_in?
    Sentry.set_user(id: current_user.id, email: current_user.email, role: current_user.role)
  end

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
  before_action :store_referral_token

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
      'accelerometer=(), autoplay=()',
      'encrypted-media=(), fullscreen=(self), picture-in-picture=()'
    ].join(', ')

    if Rails.env.production?
      # Strict-Transport-Security : Forcer HTTPS
      response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload'

      # Expect-CT : Certificate Transparency
      response.headers['Expect-CT'] = 'max-age=86400, enforce'
    end

    # Empêcher le cache HTTP des pages authentifiées (évite la fuite de données cross-user)
    # Critical : sans cela, Heroku/proxy/navigateur peut servir la page d'un autre utilisateur
    response.headers['Cache-Control'] = 'private, no-store, no-cache, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    # Turbo Drive : aucun stockage snapshot (no-preview insuffisant — no-store empêche toute mise en cache)
    response.headers['Turbo-Cache-Control'] = 'no-store'
    # Thruster (proxy Rails 8) : empêcher le cache des réponses dynamiques authentifiées
    response.headers['Vary'] = 'Cookie'
  end

  protected

  def configure_permitted_parameters
    # Pour l'inscription
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :professional_type])

    # Pour la mise à jour du compte
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :professional_type])
  end

  def store_referral_token
    session[:referral_token] = params[:ref] if params[:ref].present?
  end

  def after_sign_in_path_for(resource)
    stored = stored_location_for(resource)
    return stored if stored.present?
    resource.onboarding_done? ? dashboard_path : onboarding_profile_selection_path(locale: I18n.locale)
  end

  def after_sign_up_path_for(resource)
    onboarding_profile_selection_path(locale: I18n.locale)
  end

  def ensure_admin_or_moderator
    unless current_user&.admin? || current_user&.moderator?
      redirect_to root_path, alert: "Accès non autorisé. Vous devez être administrateur ou modérateur."
    end
  end

  PLAN_EXEMPT_EMAIL = 'robin@primes-services.be'.freeze

  def plan_exempt?
    user_signed_in? && current_user.email == PLAN_EXEMPT_EMAIL
  end
  helper_method :plan_exempt?

  # Valider qu'une URL externe pointe vers un hôte de confiance avant redirection
  TRUSTED_REDIRECT_HOSTS = %w[
    res.cloudinary.com
    res-1.cloudinary.com
    res-2.cloudinary.com
    res-3.cloudinary.com
    res-4.cloudinary.com
  ].freeze

  def safe_external_url?(url)
    return false if url.blank?
    uri = URI.parse(url)
    TRUSTED_REDIRECT_HOSTS.any? { |host| uri.host == host || uri.host&.end_with?(".cloudinary.com") }
  rescue URI::InvalidURIError
    false
  end
end
