# Configuration des headers de sécurité avancée
Rails.application.configure do
  # Activer Secure Headers dans le middleware
  config.force_ssl = Rails.env.production? # HTTPS obligatoire en production

  # Configuration des headers de sécurité additionnels
  config.middleware.use Rack::HeaderSafe if defined?(Rack::HeaderSafe)
end
