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

    # À réactiver si tu utilises node_modules pour Bootstrap, etc.
    # config.assets.paths << Rails.root.join("node_modules")
  end
end
