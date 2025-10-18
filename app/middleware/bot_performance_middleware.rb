class BotPerformanceMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Optimisations spécifiques pour les requêtes du bot
    if bot_request?(env)
      # Headers pour optimiser les performances
      env['HTTP_CACHE_CONTROL'] = 'no-cache'
      env['HTTP_PRAGMA'] = 'no-cache'

      # Mesure du temps de réponse
      start_time = Time.current

      status, headers, response = @app.call(env)

      # Log des performances si lent
      duration = Time.current - start_time
      if duration > 0.5 # Plus de 500ms
        Rails.logger.warn "Slow bot response: #{duration.round(3)}s for #{env['REQUEST_URI']}"
      end

      # Headers de performance
      headers['X-Response-Time'] = "#{(duration * 1000).round(2)}ms"

      [status, headers, response]
    else
      @app.call(env)
    end
  end

  private

  def bot_request?(env)
    env['REQUEST_URI']&.include?('/api/contextual_bot')
  end
end
