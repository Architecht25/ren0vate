Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']

  # Activer uniquement en production (pas de bruit en dev/test)
  config.enabled_environments = %w[production]

  # Breadcrumbs Rails : requêtes, ActiveRecord, cache, jobs
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Performance monitoring — 10% des transactions pour rester dans le plan gratuit
  config.traces_sample_rate = 0.1

  # Ne pas envoyer les erreurs de routing (404, bots) ni les exceptions connues
  config.excluded_exceptions += %w[
    ActionController::RoutingError
    ActionController::UnknownFormat
    ActiveRecord::RecordNotFound
    Rack::Attack::Error
  ]

  # Filtrer les données sensibles avant envoi
  config.before_send = lambda do |event, _hint|
    # Masquer les params sensibles (Sentry filtre déjà password/token par défaut)
    if event.request&.data.is_a?(Hash)
      event.request.data.delete("iban")
      event.request.data.delete("national_number")
    end
    event
  end

  # Identifier l'utilisateur dans les erreurs (sans données sensibles)
  # Géré manuellement via set_sentry_user dans ApplicationController
end
