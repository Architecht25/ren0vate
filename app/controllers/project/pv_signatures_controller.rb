class PvSignaturesController < ApplicationController
  # Page de signature publique — accessible SANS authentification
  skip_before_action :authenticate_user!, raise: false

  before_action :find_pv_and_role

  # GET /pv/:token
  def show
    # @pv et @role sont chargés par before_action
  end

  # POST /pv/:token
  def sign
    if @pv.deja_signe_avec_token?(params[:token])
      return redirect_to pv_signature_path(params[:token]),
                         alert: "Vous avez déjà signé ce PV."
    end

    if @pv.finalise?
      return redirect_to pv_signature_path(params[:token]),
                         alert: "Ce PV est déjà finalisé."
    end

    commentaire = params[:commentaire].to_s.strip.truncate(500)
    @pv.signer!(@role, commentaire: commentaire.presence)

    redirect_to pv_signature_path(params[:token]),
                notice: "Votre signature a bien été enregistrée. Merci !"
  end

  private

  def find_pv_and_role
    @pv = PvReception.find_by_token(params[:token])

    unless @pv
      render plain: "Lien de signature invalide ou expiré.", status: :not_found
      return
    end

    @role = @pv.role_pour_token(params[:token])
    unless @role
      render plain: "Token invalide.", status: :not_found
      nil
    end
  end
end
