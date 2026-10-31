# V2 — Lot 1 : base documentaire versionnée. Distinct de Documents::DocumentsController
# (Document V1) — voir docs/PLAN_V2.md Lot 1 pour pourquoi les deux coexistent.
class ProjectDocumentsController < ApplicationController
  before_action :check_dossier_documentaire_access!
  before_action :set_project, only: %i[index new create]
  before_action :set_project_document, only: %i[show destroy add_version accept_suggestion translate]

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

  # V2 — Lot 2 : confirmation humaine explicite d'une proposition de
  # classification IA (cahier des charges §8 : "l'IA ne décide jamais").
  def accept_suggestion
    authorize @project_document, :update?

    if @project_document.apply_ai_suggestion!
      AiRun.where(subject: @project_document.current_version).order(created_at: :desc).first&.mark_validated!(by: current_user)
      AuditEvent.record!(action: "project_document.suggestion_accepted", auditable: @project_document, actor: current_user, ip_address: request.remote_ip)
      redirect_to project_document_path(@project_document), notice: "Suggestion appliquée."
    else
      redirect_to project_document_path(@project_document), alert: "Aucune suggestion disponible."
    end
  end

  def destroy
    authorize @project_document
    @project_document.destroy!
    redirect_to project_project_documents_path(@project_document.project), notice: "Document supprimé."
  end

  # V2 — Lot 5 : traduction à la demande (cahier des charges §8.8 — "avec
  # affichage du texte original"). Le texte OCR original n'est jamais
  # remplacé, seule la traduction est renvoyée en JSON pour un affichage
  # côte à côte côté vue.
  def translate
    authorize @project_document, :show?
    text = @project_document.current_version&.ocr_text
    # target_locale, PAS locale — ce dernier est déjà le segment de route
    # global (fr/nl/en/es de l'interface), une collision de nom aurait fait
    # écraser l'un par l'autre de façon imprévisible.
    translation = text.present? ? Ai::TranslationService.new(project: @project_document.project, actor: current_user).translate(text, to: params[:target_locale]) : nil

    render json: { translation: translation }
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
