# V2 — Lot 6 : garanties (cahier des charges §5.E).
class WarrantiesController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_warranty, only: %i[destroy]

  def index
    authorize @project, :show?
    @warranties = policy_scope(Warranty).where(project: @project).order(:end_date)
  end

  def new
    @warranty = @project.warranties.build
    authorize @warranty, :create?
  end

  def create
    @warranty = @project.warranties.build(warranty_params)
    authorize @warranty, :create?

    if @warranty.save
      redirect_to project_warranties_path(@project), notice: "Garantie ajoutée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @warranty, :destroy?
    project = @warranty.project
    @warranty.destroy!
    redirect_to project_warranties_path(project), notice: "Garantie supprimée."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_warranty
    @warranty = Warranty.find(params[:id])
  end

  def warranty_params
    params.require(:warranty).permit(:label, :lot_id, :start_date, :end_date, :project_document_id)
  end
end
