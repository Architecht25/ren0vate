class ReservesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :authorize_project_access!
  before_action :set_reserve, only: %i[update destroy]

  # POST /projects/:project_id/reserves
  def create
    @reserve = @project.reserves.build(reserve_params)
    @reserve.date_constat ||= Date.current

    if @reserve.save
      redirect_to reception_chantier_project_path(@project, anchor: 'reserves'),
                  notice: "Réserve ajoutée."
    else
      redirect_to reception_chantier_project_path(@project, anchor: 'reserves'),
                  alert: "Erreur : #{@reserve.errors.full_messages.to_sentence}"
    end
  end

  # PATCH /projects/:project_id/reserves/:id
  def update
    if @reserve.update(reserve_params)
      redirect_to reception_chantier_project_path(@project, anchor: 'reserves'),
                  notice: "Réserve mise à jour."
    else
      redirect_to reception_chantier_project_path(@project, anchor: 'reserves'),
                  alert: "Erreur : #{@reserve.errors.full_messages.to_sentence}"
    end
  end

  # DELETE /projects/:project_id/reserves/:id
  def destroy
    @reserve.destroy
    redirect_to reception_chantier_project_path(@project, anchor: 'reserves'),
                notice: "Réserve supprimée."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_reserve
    @reserve = @project.reserves.find(params[:id])
  end

  def authorize_project_access!
    is_owner = @project.user_id == current_user.id
    is_member = @project.project_members.active.where(user: current_user).exists?
    unless is_owner || is_member
      redirect_to root_path, alert: "Accès non autorisé."
    end
  end

  def reserve_params
    params.require(:reserve).permit(
      :description, :responsable, :date_constat, :date_limite, :statut, :notes,
      :photo, :pin_x, :pin_y, :plan_document_id, :etage
    )
  end
end
