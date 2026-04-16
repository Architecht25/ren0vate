class ProjectChecklistsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :authorize_project_access!

  # POST /projects/:project_id/project_checklists
  def create
    template = ChecklistTemplate.find(params[:checklist_template_id])
    @checklist = @project.project_checklists.build(checklist_template: template)

    if @checklist.save
      redirect_to project_project_checklist_path(@project, @checklist),
                  notice: "Inspection « #{template.name} » démarrée."
    else
      redirect_to reception_chantier_project_path(@project, anchor: 'checklists'),
                  alert: "Impossible de démarrer l'inspection."
    end
  end

  # GET /projects/:project_id/project_checklists/:id
  def show
    @checklist = @project.project_checklists
                          .includes(project_checklist_items: :checklist_item)
                          .find(params[:id])
    @items = @checklist.project_checklist_items
                       .joins(:checklist_item)
                       .order('checklist_items.position')
  end

  # DELETE /projects/:project_id/project_checklists/:id
  def destroy
    checklist = @project.project_checklists.find(params[:id])
    checklist.destroy
    redirect_to reception_chantier_project_path(@project, anchor: 'checklists'),
                notice: "Inspection supprimée."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def authorize_project_access!
    is_owner  = @project.user_id == current_user.id
    is_member = @project.project_members.active.where(user: current_user).exists?
    redirect_to root_path, alert: "Accès non autorisé." unless is_owner || is_member
  end
end
