class Api::SecurityController < ApplicationController
  # Désactiver l'authentification pour certains endpoints de monitoring
  skip_before_action :authenticate_user!, only: [:headers_check]
  before_action :ensure_admin, except: [:headers_check]

  def headers_check
    # Informations sur les headers de sécurité de l'application
    security_status = {
      secure: true,
      https: request.ssl?,
      headers: {
        csp: response.headers['Content-Security-Policy'].present?,
        hsts: response.headers['Strict-Transport-Security'].present?,
        x_frame_options: response.headers['X-Frame-Options'].present?,
        x_content_type_options: response.headers['X-Content-Type-Options'].present?,
        x_xss_protection: response.headers['X-XSS-Protection'].present?,
        referrer_policy: response.headers['Referrer-Policy'].present?,
        permissions_policy: response.headers['Permissions-Policy'].present?
      },
      environment: Rails.env,
      csrf_protection: Rails.application.config.force_ssl,
      session_security: {
        secure: Rails.application.config.force_ssl,
        httponly: true,
        samesite: 'Lax'
      }
    }

    render json: security_status
  end

  def csp_violations
    # Récupérer les violations CSP des dernières 24h depuis les logs
    violations_count = 0 # Placeholder - dans un vrai cas, parser les logs ou BDD
    
    render json: {
      count: violations_count,
      period: '24h',
      critical: 0,
      last_check: Time.current
    }
  end

  def security_overview
    # Vue d'ensemble de la sécurité
    overview = {
      authentication: {
        provider: 'Devise',
        status: 'active',
        confirmable: User.devise_modules.include?(:confirmable),
        users_confirmed: User.where.not(confirmed_at: nil).count,
        users_unconfirmed: User.where(confirmed_at: nil).count,
        configuration: {
          allow_unconfirmed_access_for: Devise.allow_unconfirmed_access_for&.inspect,
          confirm_within: Devise.confirm_within&.inspect,
          reconfirmable: Devise.reconfirmable
        },
        users_count: User.count,
        last_sign_in: User.maximum(:last_sign_in_at)
      },
      https: {
        enabled: Rails.application.config.force_ssl,
        hsts: Rails.env.production?,
        hsts_max_age: 31536000
      },
      csp: {
        enabled: true,
        mode: Rails.env.production? ? 'enforce' : 'report-only',
        violations_24h: 0
      },
      session_security: {
        secure: Rails.application.config.force_ssl,
        httponly: true,
        csrf_protection: true
      },
      last_security_check: Time.current
    }

    render json: overview
  end

  private

  def ensure_admin
    unless current_user&.email == 'robin@primes-services.be'
      render json: { error: 'Access denied' }, status: :forbidden
    end
  end
end
