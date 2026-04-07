class PwaController < ApplicationController
  # Pas besoin d'authentification pour le manifest et le service worker
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, only: [:service_worker]

  def manifest
    respond_to do |format|
      format.json { render layout: false }
    end
  end

  def service_worker
    # Le Service Worker doit avoir la permission de contrôler tout le scope /
    response.headers["Service-Worker-Allowed"] = "/"
    # Cache court — on veut que les mises à jour se propagent rapidement
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    render layout: false, content_type: "application/javascript"
  end
end
