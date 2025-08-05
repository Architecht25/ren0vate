class Api::BceController < ApplicationController
  # Pas d'authentification nécessaire pour la recherche publique d'entreprises
  skip_before_action :authenticate_user!
  protect_from_forgery with: :null_session

  def search
    enterprise_number = params[:enterprise_number]

    if enterprise_number.blank?
      render json: { error: 'Numéro d\'entreprise requis' }, status: :bad_request
      return
    end

    result = BceApiService.search_company(enterprise_number)

    if result[:error]
      render json: result, status: :not_found
    else
      render json: result
    end
  end
end
