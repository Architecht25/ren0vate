class PrimesHubController < ApplicationController
  before_action :authenticate_user!

  def index
    @property = current_user.properties.find_by(id: params[:property_id]) if params[:property_id].present?
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

    # Wallonie — dossiers de prêt bonifié (régime "reduction_pret", dès le 01/10/2026).
    # Distinct du couple Request/RequestProgress ci-dessus, conçu pour des primes cash
    # traitées par une administration régionale — le prêt bonifié suit un cycle de vie
    # propre (voir PretWallonieDossier).
    @pret_wallonie_dossiers = current_user.pret_wallonie_dossiers.includes(:project).order(updated_at: :desc)
    @pret_wallonie_dossiers_count = @pret_wallonie_dossiers.count

    dossier_project_ids = @pret_wallonie_dossiers.map(&:project_id)
    @pret_wallonie_eligible_simulations = current_user.simulations
                                                       .where(region: "wallonie", regime: "reduction_pret", eligible: true)
                                                       .where.not(project_id: nil)
                                                       .where.not(project_id: dossier_project_ids)
                                                       .order(created_at: :desc)
  end
end
