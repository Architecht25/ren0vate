# V2 — Lot 1 : base documentaire versionnée. Distinct de Documents::DocumentsController
# (Document V1) — voir docs/PLAN_V2.md Lot 1 pour pourquoi les deux coexistent.
class ProjectDocumentsController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_project_document, only: %i[show destroy add_version]

  def index
    authorize_project_scope!
    @project_documents = policy_scope(ProjectDocument).where(project: @project).includes(:lot, :phase, :uploaded_by)
  end

  def show
    authorize @project_document
    AuditEvent.record!(action: "project_document.viewed", auditable: @project_document, actor: current_user, ip_address: request.remote_ip)
    @comments = @project_document.comments.includes(:author).order(:created_at)
    @reviews = @project_document.reviews.includes(:reviewer).order(created_at: :desc)
  end

  def new
    authorize_project_scope!
    @project_document = @project.project_documents.build
    @project_document.versions.build
  end

  def create
    authorize_project_scope!
    @project_document = @project.project_documents.build(project_document_params)
    @project_document.uploaded_by = current_user
    @project_document.versions.each { |version| version.created_by = current_user }

    if @project_document.save
      AuditEvent.record!(action: "project_document.created", auditable: @project_document, actor: current_user, ip_address: request.remote_ip)
      redirect_to project_document_path(@project_document), notice: "Document ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def add_version
    authorize @project_document, :add_version?
    version = @project_document.versions.build(created_by: current_user, file: params.dig(:project_document_version, :file))

    if version.save
      AuditEvent.record!(action: "project_document.version_added", auditable: @project_document, actor: current_user, ip_address: request.remote_ip, event_data: { version_number: version.version_number })
      redirect_to project_document_path(@project_document), notice: "Nouvelle version ajoutée."
    else
      redirect_to project_document_path(@project_document), alert: version.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize @project_document
    @project_document.destroy!
    redirect_to project_project_documents_path(@project_document.project), notice: "Document supprimé."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
    authorize @project, :show?
  end

  def set_project_document
    @project_document = ProjectDocument.find(params[:id])
    @project = @project_document.project
  end

  # #new/#create n'ont pas encore de record ProjectDocument persistant à
  # passer à `authorize` — la permission de créer se vérifie sur le projet
  # parent (ProjectDocumentPolicy#create? gère owner/membre actif).
  def authorize_project_scope!
    authorize @project, :show?
    raise Pundit::NotAuthorizedError unless ProjectDocumentPolicy.new(current_user, @project.project_documents.build).create?
  end

  def project_document_params
    params.require(:project_document).permit(
      :title, :document_type, :visibility, :lot_id, :phase_id,
      versions_attributes: [:file]
    )
  end
end
