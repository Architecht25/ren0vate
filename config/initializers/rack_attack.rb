class Rack::Attack
  # Throttle : 5 tentatives de login par IP sur 20 secondes
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # Throttle : 10 tentatives de login par email sur 5 minutes (détecte credential stuffing)
  throttle("logins/email", limit: 10, period: 5.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email").to_s.downcase.strip.presence
    end
  end

  # Throttle : 3 inscriptions par IP sur 10 minutes (anti création de comptes en masse)
  throttle("signups/ip", limit: 3, period: 10.minutes) do |req|
    req.ip if req.path.match?(%r{\A/(fr|nl|en)/users/inscription\z}) && req.post?
  end

  # Throttle : endpoints API (chatbot, IA) — 30 req/minute par IP
  throttle("api/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Blocage global : 300 req/5min par IP (protection DDoS basique)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Réponse personnalisée pour les requêtes bloquées
  self.throttled_responder = lambda do |req|
    retry_after = (req.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{ error: "Trop de tentatives. Réessayez dans quelques instants." }.to_json]
    ]
  end
end

# Activer Rack::Attack dans le middleware Rails
Rails.application.config.middleware.use Rack::Attack
