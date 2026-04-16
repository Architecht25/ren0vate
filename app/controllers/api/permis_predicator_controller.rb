class Api::PermisPredicatorController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  # POST /api/permis_predicator/:project_id
  def predict
    @project = Project.find(params[:project_id])

    # Vérification accès
    unless can_access_project?(@project)
      return render json: { error: 'Accès non autorisé' }, status: :forbidden
    end

    result = PermisPredicatorService.new(@project).predict

    render json: result
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Projet introuvable' }, status: :not_found
  rescue => e
    Rails.logger.error "PermisPredicator Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    render json: { error: 'Erreur lors de l\'analyse' }, status: :unprocessable_entity
  end

  private

  def can_access_project?(project)
    project.user_id == current_user.id ||
      project.project_members.active.where(user: current_user).exists?
  end
end
