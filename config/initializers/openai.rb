OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY")
  config.organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID", nil) # Optionnel
  config.log_errors = Rails.env.development? # Log les erreurs uniquement en développement
end
