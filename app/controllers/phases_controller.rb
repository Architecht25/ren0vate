# V2 — gestion des phases d'un chantier (cahier des charges §4 :
# "personnalisables"). Réutilise PhasePolicy — mêmes règles que LotPolicy.
class PhasesController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_phase, only: %i[edit update destroy]

  def index
    authorize @project, :show?
    @phases = @project.phases.ordered
  end

  def new
    @phase = @project.phases.build(position: @project.phases.maximum(:position).to_i + 1)
    authorize @phase, :create?
  end

  def create
    @phase = @project.phases.build(phase_params)
    authorize @phase, :create?

    if @phase.save
      redirect_to project_phases_path(@project), notice: "Phase ajoutée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @phase, :update?
  end

  def update
    authorize @phase, :update?

    if @phase.update(phase_params)
      redirect_to project_phases_path(@phase.project), notice: "Phase modifiée."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @phase, :destroy?
    project = @phase.project
    @phase.destroy!
    redirect_to project_phases_path(project), notice: "Phase supprimée."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_phase
    @phase = Phase.find(params[:id])
  end

  def phase_params
    params.require(:phase).permit(:key, :name, :position)
  end
end
