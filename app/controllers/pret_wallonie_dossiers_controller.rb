class PretWallonieDossiersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_dossier, only: %i[show update]

  # GET /projects/:project_id/pret_wallonie_dossier
  def show
    redirect_to new_dossier_redirect_path and return unless @dossier

    @dossier.resync_from_simulation!
  end

  # POST /projects/:project_id/pret_wallonie_dossier
  # Démarre le suivi à partir de la dernière simulation "reduction_pret" éligible du projet.
  def create
    simulation = @project.simulations
                          .where(region: "wallonie", regime: "reduction_pret", eligible: true)
                          .order(created_at: :desc)
                          .first

    unless simulation
      redirect_to project_path(@project), alert: "Aucune simulation éligible au prêt bonifié wallon n'a été trouvée pour ce projet."
      return
    end

    @dossier = PretWallonieDossier.build_from_simulation(simulation, user: current_user)

    if @dossier.save
      redirect_to project_pret_wallonie_dossier_path(@project), notice: "Suivi de votre demande de prêt démarré."
    else
      redirect_to project_path(@project), alert: @dossier.errors.full_messages.to_sentence
    end
  end

  # PATCH /projects/:project_id/pret_wallonie_dossier
  def update
    if @dossier.update(dossier_params)
      redirect_to project_pret_wallonie_dossier_path(@project), notice: "Suivi mis à jour."
    else
      redirect_to project_pret_wallonie_dossier_path(@project), alert: @dossier.errors.full_messages.to_sentence
    end
  end

  private

  def set_project
    @project = current_user.projects.find_by(id: params[:project_id])
    @project ||= Project
                   .joins(:project_members)
                   .where(project_members: { user_id: current_user.id, status: "active" })
                   .find_by(id: params[:project_id])
    redirect_to root_path, alert: "Projet introuvable." unless @project
  end

  def set_dossier
    @dossier = @project.pret_wallonie_dossier
  end

  def new_dossier_redirect_path
    project_path(@project)
  end

  def dossier_params
    params.require(:pret_wallonie_dossier).permit(
      :statut, :date_depot, :date_signature, :date_cloture,
      :label_peb_apres_travaux, :notes
    )
  end
end
