# V2 — Lot 4 : planning par lot (cahier des charges §5.D). Pas de page
# edit dédiée — la seule modification courante est le changement de statut,
# fait en place depuis l'index (voir #update).
class ScheduleItemsController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_item, only: %i[update destroy]

  def index
    authorize @project, :show?
    @schedule_items = policy_scope(ScheduleItem).where(project: @project).includes(:lot, :depends_on).order(:start_date)
  end

  def new
    @item = @project.schedule_items.build
    authorize @item, :create?
  end

  def create
    @item = @project.schedule_items.build(item_params)
    authorize @item, :create?

    if @item.save
      redirect_to project_schedule_items_path(@project), notice: "Tâche ajoutée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @item, :update?
    @item.update(status: params[:status]) if ScheduleItem.statuses.key?(params[:status])
    redirect_to project_schedule_items_path(@item.project)
  end

  def destroy
    authorize @item, :destroy?
    project = @item.project
    @item.destroy!
    redirect_to project_schedule_items_path(project), notice: "Tâche supprimée."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_item
    @item = ScheduleItem.find(params[:id])
  end

  def item_params
    params.require(:schedule_item).permit(:label, :lot_id, :start_date, :end_date, :depends_on_id)
  end
end
