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
    config.active_storage.max_file_size = 30.megabytes

    # Configuration ActionMailbox pour la réception d'emails
    config.action_mailbox.ingress = :postmark

    # À réactiver si tu utilises node_modules pour Bootstrap, etc.
    # config.assets.paths << Rails.root.join("node_modules")

    # Middleware de performance pour le bot contextuel
    # config.middleware.use BotPerformanceMiddleware
  end
end
