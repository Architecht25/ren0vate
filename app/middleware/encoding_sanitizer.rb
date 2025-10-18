class EncodingSanitizer
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      # Traiter la requête normalement
      @app.call(env)
    rescue Rack::QueryParser::InvalidParameterError => e
      # Journaliser l'erreur
      Rails.logger.warn "⚠️ Erreur d'encodage interceptée: #{e.message}"

      # Retourner une réponse JSON propre
      [400,
       {'Content-Type' => 'application/json'},
       [JSON.generate({
         error: 'Caractères invalides détectés',
         message: 'Veuillez utiliser uniquement des caractères standard',
         status: 400
       })]]
    rescue ActionController::BadRequest => e
      if e.message.include?('Invalid encoding')
        Rails.logger.warn "⚠️ Erreur d'encodage interceptée: #{e.message}"

        [400,
         {'Content-Type' => 'application/json'},
         [JSON.generate({
           error: 'Problème d\'encodage détecté',
           message: 'Veuillez reformuler votre message',
           status: 400
         })]]
      else
        # Re-lever l'erreur si ce n'est pas un problème d'encodage
        raise e
      end
    end
  end
end
