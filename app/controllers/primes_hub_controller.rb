class PrimesHubController < ApplicationController
  before_action :authenticate_user!

  def index
    # Dernières simulations (max 3 pour l'aperçu)
    @simulations = current_user.simulations.includes(:property)
                               .order(created_at: :desc)
                               .limit(3)
    @simulations_count = current_user.simulations.count

    # Formulaires de demande
    @requests = current_user.requests.includes(:property)
                            .order(created_at: :desc)
                            .limit(3)
    @requests_count = current_user.requests.count

    # Suivi des primes
    user_progresses = RequestProgress.joins(:request)
                                     .where(requests: { user_id: current_user.id })
                                     .includes(:request, :prime)

    @progresses_count = user_progresses.count
    @progresses = user_progresses.order(updated_at: :desc).limit(3)

    @stats = {
      total: @progresses_count,
      en_attente: user_progresses.en_attente.count,
      accordees: user_progresses.where(status_administratif: 'accorde').count,
      montant_total: user_progresses.where(status_administratif: 'accorde').sum(:montant_accorde).to_f
    }
  end
end
