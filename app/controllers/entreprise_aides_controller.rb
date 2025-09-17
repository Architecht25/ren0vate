class EntrepriseAidesController < ApplicationController
  def show
    @entreprise_aide = EntrepriseAide.find(params[:id])
  end
end
