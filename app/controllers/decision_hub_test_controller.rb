class DecisionHubTestController < ApplicationController
  before_action :authenticate_user!

  def index
    # Page de test pour accéder au Decision Hub
    @simulations = current_user.simulations.where.not(total_simule: nil)
                                           .where('total_simule > 0')
                                           .order(created_at: :desc)
                                           .limit(10)
  end
end
