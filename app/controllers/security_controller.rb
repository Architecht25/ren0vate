class SecurityController < ApplicationController
  # Désactiver l'authentification pour ce endpoint
  skip_before_action :authenticate_user!, only: [:csp_violation_report]
  # Désactiver la vérification CSRF pour les rapports CSP
  skip_before_action :verify_authenticity_token, only: [:csp_violation_report]

  def csp_violation_report
    # Parser le rapport CSP (JSON)
    begin
      report = JSON.parse(request.body.read)

      # Logger le rapport pour analyse
      Rails.logger.warn "[CSP VIOLATION] #{report.inspect}"

      # En production, on pourrait :
      # - Envoyer à un service de monitoring (Sentry, DataDog, etc.)
      # - Stocker en base pour analyse
      # - Envoyer un email aux administrateurs si critique

      # Exemple de logging structuré
      log_csp_violation(report)

      # Répondre avec succès pour que le navigateur ne retry pas
      head :no_content

    rescue JSON::ParserError => e
      Rails.logger.error "[CSP VIOLATION] Invalid JSON: #{e.message}"
      head :bad_request
    rescue => e
      Rails.logger.error "[CSP VIOLATION] Error processing report: #{e.message}"
      head :internal_server_error
    end
  end

  private

  def log_csp_violation(report)
    # Extraire les informations importantes du rapport
    violation_data = {
      timestamp: Time.current,
      user_agent: request.user_agent,
      ip_address: request.remote_ip,
      referrer: request.referrer,
      csp_report: report
    }

    # Logger de manière structurée
    Rails.logger.warn "[CSP VIOLATION DETAILS] #{violation_data.to_json}"

    # Si la violation est critique (tentative d'injection), on peut alerter
    if critical_violation?(report)
      Rails.logger.error "[CSP CRITICAL VIOLATION] Possible security threat detected: #{violation_data.to_json}"
      # Ici on pourrait envoyer une notification aux admins
    end
  end

  def critical_violation?(report)
    # Détecter les violations critiques qui pourraient indiquer une attaque
    return false unless report['csp-report']

    violation = report['csp-report']
    blocked_uri = violation['blocked-uri'] || ''

    # Signes d'une possible attaque XSS
    suspicious_patterns = [
      /javascript:/i,
      /data:.*javascript/i,
      /eval\(/i,
      /<script/i,
      /vbscript:/i
    ]

    suspicious_patterns.any? { |pattern| blocked_uri.match?(pattern) }
  end
end
