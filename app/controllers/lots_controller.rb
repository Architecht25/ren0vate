# V2 — gestion des lots d'un chantier (cahier des charges §4 :
# "personnalisables"). Policy déjà posée au Lot 0 (app/policies/lot_policy.rb)
# — seul le propriétaire gère les lots, voir LotPolicy pour la décision non
# tranchée sur l'extension de ce droit à l'architecte.
class LotsController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_lot, only: %i[edit update destroy]

  def index
    authorize @project, :show?
    @lots = @project.lots.ordered
  end

  def new
    @lot = @project.lots.build(position: @project.lots.maximum(:position).to_i + 1)
    authorize @lot, :create?
  end

  def create
    @lot = @project.lots.build(lot_params)
    authorize @lot, :create?

    if @lot.save
      redirect_to project_lots_path(@project), notice: "Lot ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @lot, :update?
  end

  def update
    authorize @lot, :update?

    if @lot.update(lot_params)
      redirect_to project_lots_path(@lot.project), notice: "Lot modifié."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @lot, :destroy?
    project = @lot.project
    @lot.destroy!
    redirect_to project_lots_path(project), notice: "Lot supprimé."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_lot
    @lot = Lot.find(params[:id])
  end

  def lot_params
    params.require(:lot).permit(:key, :name, :position)
  end
end
