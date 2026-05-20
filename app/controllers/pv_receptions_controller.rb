class PvReceptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :authorize_creator!, only: %i[create destroy send_signatures]
  before_action :set_pv,            only: %i[show destroy send_signatures print]

  # GET /projects/:project_id/pv_reception
  def show
  end

  # GET /projects/:project_id/pv_reception/print
  def print
    render layout: "print"
  end

  # POST /projects/:project_id/pv_receptions
  def create
    if @project.pv_reception.present?
      return redirect_to project_pv_reception_path(@project),
                         notice: "Un PV existe déjà pour ce projet."
    end

    members      = @project.project_members.active.includes(:user)
    arch_member  = members.find { |m| m.role == "architect" }
    entr_member  = members.find { |m| m.role == "entrepreneur" }
    owner        = @project.user

    reserves = @project.reserves.order(statut: :asc, created_at: :desc).map do |r|
      { description: r.description, statut: r.statut_label, responsable: r.responsable,
        date_constat: r.date_constat&.strftime("%d/%m/%Y"),
        date_limite:  r.date_limite&.strftime("%d/%m/%Y") }
    end

    lots = begin
      raw = params.dig(:pv_reception, :lots_reception_json)
      raw.present? ? JSON.parse(raw) : []
    rescue JSON::ParserError
      []
    end

    @pv = @project.build_pv_reception(
      date_reception:       params.dig(:pv_reception, :date_reception).presence || Date.current,
      heure_reception:      params.dig(:pv_reception, :heure_reception).presence,
      meteo:                params.dig(:pv_reception, :meteo).presence,
      presents:             params.dig(:pv_reception, :presents).presence,
      absents:              params.dig(:pv_reception, :absents).presence,
      coordinateur_sps:     params.dig(:pv_reception, :coordinateur_sps).presence,
      observations:         params.dig(:pv_reception, :observations).presence,
      lots_reception:       lots,
      # Owner (toujours le project.user, indépendamment de qui crée le PV)
      nom_owner:            owner.full_name,
      email_owner:          owner.email,
      # Architecte
      nom_architect:        arch_member&.user&.full_name || @project.architecte_nom_complet.presence,
      email_architect:      arch_member&.user&.email     || @project.architecte_email.presence,
      # Entrepreneur
      nom_entrepreneur:     entr_member&.user&.full_name ||
                            @project.entrepreneur_principal_nom.presence ||
                            @project.entrepreneur_principal_entreprise,
      email_entrepreneur:   entr_member&.user&.email     || @project.entrepreneur_principal_email.presence,
      reserves_snapshot:    reserves.to_json
    )

    if @pv.save
      redirect_to project_pv_reception_path(@project),
                  notice: "PV créé. Vous pouvez maintenant l'envoyer pour signature."
    else
      redirect_to reception_chantier_project_path(@project),
                  alert: "Erreur : #{@pv.errors.full_messages.to_sentence}"
    end
  end

  # POST /projects/:project_id/pv_reception/send_signatures
  def send_signatures
    if @pv.finalise?
      return redirect_to project_pv_reception_path(@project),
                         alert: "Le PV est déjà finalisé."
    end

    sent_to = []

    if @pv.email_owner.present? && !@pv.signed_owner?
      PvMailer.signature_request(@pv, :owner).deliver_later
      @pv.update_column(:sent_owner_at, Time.current) unless @pv.sent_owner_at
      sent_to << @pv.nom_owner.presence || @pv.email_owner
    end

    if @pv.email_architect.present? && !@pv.signed_architect?
      PvMailer.signature_request(@pv, :architect).deliver_later
      @pv.update_column(:sent_architect_at, Time.current) unless @pv.sent_architect_at
      sent_to << @pv.nom_architect.presence || @pv.email_architect
    end

    if @pv.email_entrepreneur.present? && !@pv.signed_entrepreneur?
      PvMailer.signature_request(@pv, :entrepreneur).deliver_later
      @pv.update_column(:sent_entrepreneur_at, Time.current) unless @pv.sent_entrepreneur_at
      sent_to << @pv.nom_entrepreneur.presence || @pv.email_entrepreneur
    end

    @pv.update_column(:statut, "envoye") if sent_to.any? && @pv.draft?

    if sent_to.any?
      redirect_to project_pv_reception_path(@project),
                  notice: "PV envoyé pour signature à : #{sent_to.join(', ')}."
    else
      redirect_to project_pv_reception_path(@project),
                  alert: "Aucun destinataire disponible (ou toutes les signatures déjà reçues)."
    end
  end

  # DELETE /projects/:project_id/pv_reception
  def destroy
    @pv.destroy
    redirect_to reception_chantier_project_path(@project),
                notice: "PV supprimé."
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

  def set_pv
    @pv = @project.pv_reception
    unless @pv
      redirect_to reception_chantier_project_path(@project),
                  alert: "Aucun PV créé pour ce projet."
    end
  end

  # L'architecte gère le PV quand il est présent ; le propriétaire sinon.
  def authorize_creator!
    has_arch     = @project.project_members.active.where(role: "architect").exists?
    is_architect = @project.project_members.active.where(user: current_user, role: "architect").exists?
    is_owner     = @project.user_id == current_user.id

    if has_arch
      unless is_architect
        redirect_to reception_chantier_project_path(@project),
                    alert: "L'architecte du projet gère le PV de réception."
      end
    else
      unless is_owner
        redirect_to reception_chantier_project_path(@project),
                    alert: "Seul le propriétaire du projet peut gérer le PV de réception."
      end
    end
  end
end
