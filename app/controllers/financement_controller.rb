class FinancementController < ApplicationController
  before_action :authenticate_user!

  # Page d'entrée unique "Financer mes travaux" : pose la question prime/prêt
  # à l'utilisateur plutôt que de le forcer à choisir en amont, dans le menu.
  # Les hubs primes_hub et loans_hub restent inchangés — cette page ne fait
  # qu'orienter vers l'un ou l'autre (voir sidebar).
  def index
    @property = current_user.properties.find_by(id: params[:property_id]) if params[:property_id].present?

    @simulations_count = current_user.simulations.count
    @requests_count = current_user.requests.count
    @pret_wallonie_dossiers_count = current_user.pret_wallonie_dossiers.count
  end
end
