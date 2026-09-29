class ProjectChecklistItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item
  before_action :authorize_project_access!

  # PATCH /project_checklist_items/:id
  def update
    if params[:checked].to_s == 'true'
      @item.check!(notes: params[:notes])
    else
      @item.uncheck!
    end

    # La checklist "contrat" est cochable depuis une carte inline sur la page
    # projet ET depuis sa page plein écran — redirect_back ramène l'utilisateur
    # là où il était plutôt que de le forcer systématiquement sur la page plein écran.
    redirect_back fallback_location: project_project_checklist_path(@project, @checklist),
                  notice: "Élément mis à jour."
  end

  private

  def set_item
    @item      = ProjectChecklistItem.find(params[:id])
    @checklist = @item.project_checklist
    @project   = @checklist.project
  end

  def authorize_project_access!
    is_owner  = @project.user_id == current_user.id
    is_member = @project.project_members.active.where(user: current_user).exists?
    redirect_to root_path, alert: "Accès non autorisé." unless is_owner || is_member
  end
end
