class ProjectNotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project

  # POST /projects/:project_id/project_notes
  def create
    @note = @project.project_notes.build(note_params)
    @note.save
    redirect_to project_path(@project, tab: params[:tab].presence || 'suivi'),
                status: :see_other
  end

  # DELETE /projects/:project_id/project_notes/:id
  def destroy
    @note = @project.project_notes.find(params[:id])
    @note.destroy
    redirect_to project_path(@project, tab: params[:tab].presence || 'suivi'),
                status: :see_other
  end

  private

  def set_project
    # L'utilisateur doit être propriétaire ou membre actif du projet
    @project = current_user.projects.find_by(id: params[:project_id])
    @project ||= Project
                   .joins(:project_members)
                   .where(project_members: { user_id: current_user.id, status: 'active' })
                   .find_by(id: params[:project_id])
    redirect_to root_path, alert: "Projet introuvable." unless @project
  end

  def note_params
    params.require(:project_note).permit(:content)
  end
end
