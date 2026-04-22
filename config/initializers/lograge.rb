# Lograge — structured single-line logs for Papertrail/Datadog compatibility
# Remplace les multi-lignes Rails par une ligne JSON parseable par les outils SIEM.
#
# Pour activer Papertrail : heroku addons:create papertrail --app <app>
# Pour activer Datadog    : heroku addons:create datadog-apm --app <app>

Rails.application.configure do
  config.lograge.enabled = true

  # Format JSON pour compatibilité maximale avec les agrégateurs de logs
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Ajouter des champs utiles pour le monitoring de sécurité
  config.lograge.custom_options = lambda do |event|
    {
      request_id: event.payload[:headers]&.fetch("action_dispatch.request_id", nil),
      user_agent: event.payload[:headers]&.fetch("HTTP_USER_AGENT", nil)&.slice(0, 200),
      remote_ip:  event.payload[:headers]&.fetch("action_dispatch.remote_ip", nil).to_s
    }.compact
  end

  # Exclure les health-checks du log pour ne pas polluer les alertes
  config.lograge.ignore_actions = ["PagesController#health"]
end
