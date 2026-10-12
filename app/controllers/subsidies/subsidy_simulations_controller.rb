# V2 — Lot 3 : simulation publique de primes (cahier des charges §9 : "mode
# simulation : publique, sans compte, avant tout suivi"). Distinct de
# Subsidies::SimulationsController (V1, modèle Simulation, rattaché à un
# compte dès la connexion) — ce contrôleur ne nécessite jamais d'être
# connecté.
class SubsidySimulationsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create show]
  skip_before_action :store_referral_token, only: %i[new create show]

  def new
  end

  def create
    input_data = simulation_input_params.to_h
    input_data["property"] = (input_data["property"] || {}).merge("region" => params[:region])

    @subsidy_case = SubsidyCase.new(
      region: params[:region],
      mode: "simulation",
      user: current_user,
      input_data: input_data
    )

    if @subsidy_case.save
      @subsidy_case.recalculate!
      redirect_to subsidy_simulation_path(@subsidy_case)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @subsidy_case = SubsidyCase.find(params[:id])
    authorize @subsidy_case
    @results = @subsidy_case.latest_results.includes(:subsidy_rule)
  end

  private

  def simulation_input_params
    params.require(:input_data).permit(
      property: [:region, :habitation_percentage, :is_main_residence, :age_years, :year_built],
      household: [:is_owner, :ownership_percentage],
      travaux: [:montant_ttc]
    )
  end
end
