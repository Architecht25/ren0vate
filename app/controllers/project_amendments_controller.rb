class ProjectAmendmentsController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_project_amendment, only: %i[decide]

  def index
    authorize_project_scope!
    @project_amendments = policy_scope(ProjectAmendment).where(project: @project).includes(:requested_by, :project_quote)
  end

  def new
    authorize_project_scope!
    @project_amendment = @project.project_amendments.build
  end

  def create
    authorize_project_scope!
    @project_amendment = @project.project_amendments.build(project_amendment_params)
    @project_amendment.requested_by = current_user

    if @project_amendment.save
      AuditEvent.record!(action: "project_amendment.proposed", auditable: @project_amendment, actor: current_user, ip_address: request.remote_ip)
      redirect_to project_project_amendments_path(@project), notice: "Avenant proposé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def decide
    authorize @project_amendment, :decide?
    status = params[:status]

    if ProjectAmendment.statuses.key?(status)
      @project_amendment.decide!(status: status, by: current_user)
      AuditEvent.record!(action: "project_amendment.decided", auditable: @project_amendment, actor: current_user, ip_address: request.remote_ip, event_data: { status: status })
      redirect_to project_project_amendments_path(@project_amendment.project), notice: "Avenant #{status}."
    else
      redirect_to project_project_amendments_path(@project_amendment.project), alert: "Statut invalide."
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
    authorize @project, :show?
  end

  def set_project_amendment
    @project_amendment = ProjectAmendment.find(params[:id])
    @project = @project_amendment.project
  end

  def authorize_project_scope!
    authorize @project, :show?
    raise Pundit::NotAuthorizedError unless ProjectAmendmentPolicy.new(current_user, @project.project_amendments.build).create?
  end

  def project_amendment_params
    params.require(:project_amendment).permit(:project_quote_id, :motif, :delta_montant)
  end
end
