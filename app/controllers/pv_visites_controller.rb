class PvVisitesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :authorize_architect!,   only: %i[create update destroy send_links]
  before_action :set_pv_visite,          only: %i[show update destroy send_links print]

  # GET /projects/:project_id/pv_visites
  def index
    @pv_visites = @project.pv_visites.chronologique
  end

  # GET /projects/:project_id/pv_visites/:id
  def show
  end

  # GET /projects/:project_id/pv_visites/:id/print
  def print
    render layout: "print"
  end

  # POST /projects/:project_id/pv_visites
  def create
    @pv_visite = @project.pv_visites.build(pv_visite_params)
    @pv_visite.auteur = current_user

    if @pv_visite.save
      redirect_to project_pv_visite_path(@project, @pv_visite),
                  notice: "PV de visite créé. Vous pouvez l'envoyer au propriétaire et à l'entrepreneur."
    else
      redirect_to suivi_path_for(@project),
                  alert: "Erreur : #{@pv_visite.errors.full_messages.to_sentence}"
    end
  end

  # PATCH /projects/:project_id/pv_visites/:id
  def update
    unless @pv_visite.draft?
      return redirect_to project_pv_visite_path(@project, @pv_visite),
                         alert: "Un PV déjà envoyé ne peut plus être modifié."
    end

    if @pv_visite.update(pv_visite_params)
      redirect_to project_pv_visite_path(@project, @pv_visite),
                  notice: "PV mis à jour."
    else
      render :show, status: :unprocessable_entity
    end
  end

  # DELETE /projects/:project_id/pv_visites/:id
  def destroy
    unless @pv_visite.draft?
      return redirect_to project_pv_visite_path(@project, @pv_visite),
                         alert: "Un PV déjà envoyé ne peut pas être supprimé."
    end

    @pv_visite.destroy
    redirect_to suivi_path_for(@project), notice: "PV de visite supprimé."
  end

  # POST /projects/:project_id/pv_visites/:id/send_links
  def send_links
    if @pv_visite.envoye?
      return redirect_to project_pv_visite_path(@project, @pv_visite),
                         notice: "Ce PV a déjà été envoyé."
    end

    sent_to = []

    owner = @project.user
    if owner.email.present? && @pv_visite.token_owner.present?
      PvVisiteMailer.partage(@pv_visite, :owner).deliver_later
      sent_to << owner.full_name.presence || owner.email
    end

    entr_member = @project.project_members.active.includes(:user).find_by(role: "entrepreneur")
    if entr_member&.user&.email.present? && @pv_visite.token_entrepreneur.present?
      PvVisiteMailer.partage(@pv_visite, :entrepreneur).deliver_later
      sent_to << entr_member.user.full_name.presence || entr_member.user.email
    end

    @pv_visite.update_column(:statut, "envoye") if sent_to.any?

    if sent_to.any?
      redirect_to project_pv_visite_path(@project, @pv_visite),
                  notice: "PV envoyé à : #{sent_to.join(', ')}."
    else
      redirect_to project_pv_visite_path(@project, @pv_visite),
                  alert: "Aucun destinataire trouvé (propriétaire ou entrepreneur avec email)."
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
    is_owner  = @project.user_id == current_user.id
    is_member = @project.project_members.active.where(user: current_user).exists?
    unless is_owner || is_member
      redirect_to projects_path, alert: "Accès non autorisé."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: "Projet introuvable."
  end

  def set_pv_visite
    @pv_visite = @project.pv_visites.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to suivi_path_for(@project), alert: "PV de visite introuvable."
  end

  def authorize_architect!
    is_architect = @project.project_members.active
                            .where(user: current_user, role: "architect")
                            .exists?
    unless is_architect
      redirect_to suivi_path_for(@project),
                  alert: "Seul l'architecte du projet peut gérer les PV de visite."
    end
  end

  # Redirige vers la vue suivi adaptée au rôle de l'utilisateur courant
  def suivi_path_for(project)
    is_architect = project.project_members.active
                          .where(user: current_user, role: "architect")
                          .exists?
    if is_architect
      pro_view_project_path(project)
    else
      project_path(project, tab: "suivi")
    end
  end

  def pv_visite_params
    p = params.require(:pv_visite).permit(
      :date_visite, :heure_visite, :meteo,
      :presents, :absents, :coordinateur_sps,
      :observations,
      :prochaine_visite, :prochaine_visite_heure
    )
    # JSONB arrays transmis comme chaînes JSON depuis le formulaire
    p[:points]    = parse_json_param(:points_json)
    p[:lots]      = parse_json_param(:lots_json)
    p[:decisions] = parse_json_param(:decisions_json)
    p
  end

  def parse_json_param(key)
    raw = params.dig(:pv_visite, key)
    raw.present? ? (JSON.parse(raw) rescue []) : []
  end
end
