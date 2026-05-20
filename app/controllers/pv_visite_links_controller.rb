class PvVisteLinksController < ApplicationController
  # Vue publique lecture seule — sans authentification
  skip_before_action :authenticate_user!, raise: false

  before_action :find_pv_and_role

  # GET /visite/:token
  def show
  end

  private

  def find_pv_and_role
    @pv_visite = PvVisite.find_by_token(params[:token])

    unless @pv_visite
      render plain: "Lien invalide ou expiré.", status: :not_found
      return
    end

    @project = @pv_visite.project
    @role    = @pv_visite.role_pour_token(params[:token])

    unless @role
      render plain: "Token invalide.", status: :not_found
    end
  end
end
