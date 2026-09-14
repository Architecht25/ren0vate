class HealthController < ActionController::Base
  # Endpoint health-check pour UptimeRobot / load balancers.
  # Hors ApplicationController : pas d'authentification, pas de CSRF, pas de Turbo.
  def show
    ActiveRecord::Base.connection.execute("SELECT 1")
    render json: { status: "ok", timestamp: Time.current.iso8601 }, status: :ok
  rescue => e
    render json: { status: "error", message: e.message }, status: :service_unavailable
  end
end
