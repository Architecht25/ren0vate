class DocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document, only: [:show, :edit, :update, :download, :destroy]
  before_action :set_context, only: [:index, :new, :create]

  # GET /documents ou /properties/:property_id/documents ou /projects/:project_id/documents
  def index
    @documents = current_user.documents.includes(:property, :project, :request, :simulation)

    # Filtrage par contexte
    @documents = @documents.where(property: @property) if @property
    @documents = @documents.where(project: @project) if @project
    @documents = @documents.where(request: @request) if @request

    # Filtrage par phase si demandé
    if params[:filter_phase].present? && @property
      @selected_phase = DocumentPhase.find(params[:filter_phase])
      @documents = @documents.by_phase(@selected_phase)
    end

    # Filtrage par type de document
    if params[:type_document].present?
      @documents = @documents.where(type_document: params[:type_document])
    end

    # Groupement par type pour l'affichage
    @documents_by_type = @documents.group_by(&:type_document)

    # Stats pour le dashboard - sécurisées
    @document_stats = {
      total: @documents.count,
      by_status: @documents.group(:status).count.transform_keys(&:to_s),
      by_type: @documents.group(:type_document).count.transform_keys(&:to_s)
    }

    # Données des phases - toujours chargées pour la navigation
    @all_phases = DocumentPhase.all.order(:position)

    # Données des phases spécifiques si c'est dans le contexte d'une propriété
    if @property
      @phases_data = @property.phases_with_status
      @phase_calculator = DocumentPhaseCalculatorService.new(@property)
    else
      # Créer des données de phases génériques pour la navigation globale
      @phases_data = @all_phases.map do |phase|
        documents_in_phase = @documents.select { |d| d.document_phase == phase }
        {
          phase: phase,
          completion_percentage: calculate_generic_completion(phase, documents_in_phase),
          documents_count: documents_in_phase.count,
          phase_status: determine_generic_status(phase, documents_in_phase),
          missing_required: calculate_missing_documents(phase, documents_in_phase),
          next_actions: []
        }
      end
    end

    # Filtrage par phase sélectionnée
    if params[:filter_phase].present?
      @selected_phase = DocumentPhase.find(params[:filter_phase])
      phase_types = @selected_phase.required_document_types + @selected_phase.optional_document_types
      @documents = @documents.where(type_document: phase_types)
    end

    # Filtrage par type de document spécifique
    if params[:type_document].present?
      @documents = @documents.where(type_document: params[:type_document])
      @selected_document_type = params[:type_document]
      # Trouver la phase correspondante pour le breadcrumb
      @selected_phase ||= DocumentPhase.find_phase_for_document_type(params[:type_document])
    end
  end

  # GET /documents/new
  def new
    @document = Document.new

    # Pré-remplir le contexte si fourni
    @document.property = @property if @property
    @document.project = @project if @project
    @document.request = @request if @request

    # Pré-remplir le type de document si fourni
    if params[:type_document].present?
      @document.type_document = params[:type_document]
    end

    # Déterminer la phase suggérée basée sur le type de document
    if @document.type_document.present?
      @suggested_phase = DocumentPhase.find_phase_for_document_type(@document.type_document)
    end

    # Mode OCR si demandé
    @ocr_mode = params[:upload_mode] == 'ocr'
    @ocr_text = params[:ocr_text] if params[:ocr_text].present?

    # Phases disponibles pour cette propriété
    if @property
      @phases_data = @property.phases_with_status
    end
  end

  # GET /documents/:id
  def show
    unless can_access_document?(@document)
      redirect_to root_path, alert: "Accès non autorisé"
      return
    end

    respond_to do |format|
      format.html # Vue prévisualisation
      format.json { render json: @document }
    end
  end

  # GET /documents/:id/edit
  def edit
    unless can_access_document?(@document)
      redirect_to root_path, alert: "Accès non autorisé"
      return
    end
  end

  # POST /documents (Upload via AJAX ou form)
  def create
    @document = current_user.documents.build(document_params)

    # Définir le statut par défaut si non fourni
    @document.status = 'pending' if @document.status.blank?

    # Définir le contexte automatiquement
    @document.property = @property if @property
    @document.project = @project if @project
    @document.request = @request if @request
    @document.simulation = @simulation if @simulation

    if @document.save
      # Générer file_url après la sauvegarde si fichier attaché
      if @document.file.attached? && @document.file_url.blank?
        @document.update(file_url: rails_blob_url(@document.file))
      end

      # Si upload via AJAX
      if request.xhr?
        render json: {
          status: 'success',
          document: document_json(@document),
          message: 'Document uploadé avec succès',
          redirect_url: documents_path
        }
      else
        redirect_to_context_or_default(notice: 'Document ajouté avec succès')
      end
    else
      if request.xhr?
        render json: {
          status: 'error',
          errors: @document.errors.full_messages
        }, status: :unprocessable_entity
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /documents/:id
  def update
    unless can_access_document?(@document)
      redirect_to root_path, alert: "Accès non autorisé"
      return
    end

    if @document.update(document_params)
      redirect_to @document, notice: 'Document mis à jour avec succès.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # GET /documents/:id/download
  def download
    unless can_access_document?(@document)
      redirect_to root_path, alert: "Accès non autorisé"
      return
    end

    if @document.file.attached?
      # Download sécurisé avec Active Storage
      redirect_to rails_blob_path(@document.file, disposition: "attachment")
    elsif @document.file_url.present?
      # Fallback pour les URLs externes
      redirect_to @document.file_url
    else
      redirect_back(fallback_location: root_path, alert: "Fichier non trouvé")
    end
  end

  # GET /documents/:id/preview
  def preview
    unless can_access_document?(@document)
      render json: { error: "Accès non autorisé" }, status: :forbidden
      return
    end

    if @document.file.attached?
      if @document.is_image?
        render json: {
          type: 'image',
          url: rails_blob_url(@document.file),
          filename: @document.file_name
        }
      elsif @document.is_pdf?
        render json: {
          type: 'pdf',
          url: rails_blob_url(@document.file),
          filename: @document.file_name
        }
      else
        render json: {
          type: 'unsupported',
          message: 'Prévisualisation non disponible pour ce type de fichier'
        }
      end
    else
      render json: { error: "Fichier non trouvé" }, status: :not_found
    end
  end

  # DELETE /documents/:id
  def destroy
    unless can_access_document?(@document)
      if request.xhr?
        render json: { status: 'error', message: 'Accès non autorisé' }, status: :forbidden
      else
        redirect_to root_path, alert: "Accès non autorisé"
      end
      return
    end

    begin
      @document.destroy

      if request.xhr?
        render json: {
          status: 'success',
          message: 'Document supprimé avec succès',
          redirect_url: documents_path
        }
      else
        redirect_to_context_or_default(notice: 'Document supprimé avec succès')
      end
    rescue => e
      Rails.logger.error "Erreur lors de la suppression du document #{@document.id}: #{e.message}"

      if request.xhr?
        render json: {
          status: 'error',
          message: 'Erreur lors de la suppression du document'
        }, status: :unprocessable_entity
      else
        redirect_to_context_or_default(alert: 'Erreur lors de la suppression du document')
      end
    end
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def set_context
    # Détecter le contexte depuis les paramètres
    @property = current_user.properties.find(params[:property_id]) if params[:property_id]
    @project = current_user.projects.find(params[:project_id]) if params[:project_id]
    @request = current_user.requests.find(params[:request_id]) if params[:request_id]
    @simulation = current_user.simulations.find(params[:simulation_id]) if params[:simulation_id]
  end

  def document_params
    params.require(:document).permit(:type_document, :status, :document_source, :file, :file_url, :property_id, :project_id, :request_id, :simulation_id)
  end

  def can_access_document?(document)
    # Vérification que l'utilisateur peut accéder au document
    document.user == current_user ||
    (document.property && document.property.user == current_user) ||
    (document.project && document.project.user == current_user)
  end

  def document_json(document)
    {
      id: document.id,
      type_document: document.type_document,
      status: document.status,
      notes: document.notes,
      file_name: document.file.attached? ? document.file.filename.to_s : nil,
      file_size: document.file.attached? ? ActionController::Base.helpers.number_to_human_size(document.file.byte_size) : nil,
      created_at: document.created_at.strftime("%d/%m/%Y à %H:%M"),
      download_url: download_document_path(document)
    }
  end

  def redirect_to_context_or_default(options = {})
    if @project
      redirect_to project_documents_path(@project), options
    elsif @property
      redirect_to property_documents_path(@property), options
    else
      redirect_to documents_path, options
    end
  end

  # Méthodes pour le calcul des métriques génériques (sans propriété)
  def calculate_generic_completion(phase, documents_in_phase)
    return 0 if phase.required_document_types.empty?

    approved_required = documents_in_phase.count { |d|
      phase.required_document_types.include?(d.type_document) && d.status == 'approved'
    }

    total_required = phase.required_document_types.length
    ((approved_required.to_f / total_required) * 100).round
  end

  def determine_generic_status(phase, documents_in_phase)
    completion = calculate_generic_completion(phase, documents_in_phase)

    case completion
    when 100 then :complete
    when 80..99 then :nearly_complete
    when 50..79 then :in_progress
    when 1..49 then :started
    else :pending
    end
  end

  def calculate_missing_documents(phase, documents_in_phase)
    existing_types = documents_in_phase.map(&:type_document)
    phase.required_document_types - existing_types
  end
end
