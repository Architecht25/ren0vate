# V2 — Lot 6 : conformité (cahier des charges §5.E).
class ComplianceItemsController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_item, only: %i[update destroy]

  def index
    authorize @project, :show?
    @compliance_items = policy_scope(ComplianceItem).where(project: @project).order(:region, :category)
  end

  def new
    @item = @project.compliance_items.build
    authorize @item, :create?
  end

  def create
    @item = @project.compliance_items.build(item_params)
    authorize @item, :create?

    if @item.save
      redirect_to project_compliance_items_path(@project), notice: "Obligation ajoutée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @item, :update?
    @item.update(status: params[:status]) if ComplianceItem.statuses.key?(params[:status])
    redirect_to project_compliance_items_path(@item.project)
  end

  def destroy
    authorize @item, :destroy?
    project = @item.project
    @item.destroy!
    redirect_to project_compliance_items_path(project), notice: "Obligation supprimée."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_item
    @item = ComplianceItem.find(params[:id])
  end

  def item_params
    params.require(:compliance_item).permit(:label, :region, :category, :due_date, :project_document_id)
  end
end
