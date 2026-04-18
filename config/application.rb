require_relative "boot"

require "rails/all"
require "importmap-rails"

Bundler.require(*Rails.groups)

module Ren0vate
  class Application < Rails::Application
    config.load_defaults 8.0

    # Nettoyage Sprockets : ligne supprimée
    # config.assets.manifest = "public/assets"

    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration de la taille maximum des uploads
    # 100MB pour permettre les photos haute résolution, validation spécifique dans le modèle Document
    config.active_storage.max_file_size = 100.megabytes

    # Configuration ActionMailbox pour la réception d'emails
    config.action_mailbox.ingress = :postmark

    # À réactiver si tu utilises node_modules pour Bootstrap, etc.
    # config.assets.paths << Rails.root.join("node_modules")

    # Middleware de performance pour le bot contextuel
    # config.middleware.use BotPerformanceMiddleware

    # Chiffrement ActiveRecord — données personnelles sensibles (IBAN, registre national, revenus)
    # Clés à définir via variables d'environnement Heroku :
    #   AR_ENCRYPTION_PRIMARY_KEY, AR_ENCRYPTION_DETERMINISTIC_KEY, AR_ENCRYPTION_KEY_DERIVATION_SALT
    # Générer avec : bin/rails db:encryption:init
    if ENV["AR_ENCRYPTION_PRIMARY_KEY"].present?
      config.active_record.encryption.primary_key        = ENV["AR_ENCRYPTION_PRIMARY_KEY"]
      config.active_record.encryption.deterministic_key  = ENV["AR_ENCRYPTION_DETERMINISTIC_KEY"]
      config.active_record.encryption.key_derivation_salt = ENV["AR_ENCRYPTION_KEY_DERIVATION_SALT"]
    end
  end
end
