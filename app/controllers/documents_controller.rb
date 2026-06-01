class DocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document, only: [:show, :edit, :update, :download, :preview, :view, :debug, :destroy, :ocr_view]
  before_action :set_context, only: [:index, :new, :create, :download_zip]

  # GET /documents ou /properties/:property_id/documents ou /projects/:project_id/documents
  def index
    @documents = current_user.documents.includes(:property, :project, :request, :simulation)

    # Filtrage par contexte
    if @project
      # Inclure les docs du projet ET les docs de la même propriété sans projet assigné
      # (ex: docs uploadés hors contexte projet mais liés au même bien)
      property_id = @project.property_id
      if property_id
        @documents = @documents.where(
          "documents.project_id = :project_id OR (documents.project_id IS NULL AND documents.property_id = :property_id)",
          project_id: @project.id, property_id: property_id
        )
      else
        @documents = @documents.where(project: @project)
      end
    elsif @property
      @documents = @documents.where(property: @property)
    end
    @documents = @documents.where(request: @request) if @request

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

    # Filtrer les phases selon le contexte utilisateur
    if @property
      # Dans le contexte d'une propriété spécifique, utiliser ses phases
      @phases_data = @property.phases_with_status
      @phase_calculator = DocumentPhaseCalculatorService.new(@property)
    else
      # Navigation globale : afficher uniquement les phases de chantier
      phases_to_show = @all_phases.chantier

      # Créer des données de phases génériques pour la navigation globale
      @phases_data = phases_to_show.map do |phase|
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
      types = Array(params[:type_document]).flatten
      @documents = @documents.where(type_document: types)
      # @selected_document_type reste nil si plusieurs types (tableau) — la vue affiche un titre générique
      @selected_document_type = types.size == 1 ? types.first : nil
      # Trouver la phase correspondante pour le breadcrumb (uniquement si type unique)
      @selected_phase ||= DocumentPhase.find_phase_for_document_type(types.first) if types.size == 1
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

    # Mode OCR si demandé, par défaut mode normal
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
    uploaded_files = params[:document][:file]
    uploaded_files = [uploaded_files] unless uploaded_files.is_a?(Array)
    upload_mode = params[:upload_mode] || 'normal'

    created_documents = []
    errors = []

    uploaded_files.each do |file|
      next if file.blank?

      # Créer un document pour chaque fichier
      document_attrs = document_params.except(:file)
      @document = current_user.documents.build(document_attrs)
      @document.file.attach(file)

      # Si mode OCR, traiter le fichier avec OCR
      facture_ocr_result = nil
      if upload_mode == 'ocr'
        begin
          # Utiliser FactureOcrService pour les factures afin d'extraire les données structurées
          if @document.type_document == 'facture'
            facture_service = FactureClaudeService.new(file)
            facture_ocr_result = facture_service.extraire_donnees_facture
            ocr_result = facture_ocr_result
          else
            ocr_service = OcrService.new(file)
            ocr_result = ocr_service.call
          end

          if ocr_result[:success]
            # Ajouter le contenu OCR aux notes
            ocr_notes = build_ocr_notes(ocr_result)
            @document.notes = ocr_notes
          else
            Rails.logger.warn "Échec OCR pour #{file.original_filename}: #{ocr_result[:error]}"
            # Continuer sans OCR en cas d'échec
          end
        rescue => e
          Rails.logger.error "Erreur OCR pour #{file.original_filename}: #{e.message}"
          # Continuer sans OCR en cas d'erreur
        end
      end

      # Définir le statut par défaut si non fourni
      @document.status = 'pending' if @document.status.blank?

      # Définir le contexte automatiquement
      @document.property = @property if @property
      @document.project = @project if @project
      # Auto-propager le bien depuis le projet si non défini
      if @project && @document.property.nil? && @project.property
        @document.property = @project.property
      end
      @document.request = @request if @request
      @document.simulation = @simulation if @simulation

      begin
        if @document.save
          # Générer file_url après la sauvegarde si fichier attaché
          if @document.file.attached? && @document.file_url.blank?
            @document.update(file_url: rails_blob_url(@document.file))
          end
          # Créer l'enregistrement Facture si OCR facture réussi et projet disponible
          project_for_facture = @project || Project.find_by(id: @document.project_id)
          if facture_ocr_result&.dig(:success) && facture_ocr_result&.dig(:donnees_facture) && project_for_facture
            creer_facture_depuis_ocr_doc(@document, facture_ocr_result, project_for_facture)
          end
          created_documents << @document
        else
          errors.concat(@document.errors.full_messages)
        end
      rescue ActiveStorage::IntegrityError => e
        if e.message.include?("File size too large")
          file_size_mb = (@document.file.byte_size.to_f / 1.megabyte).round(2) if @document.file.attached?
          # Déterminer la limite selon le type de document
          is_photo_type = %w[photo photo_avant photo_pendant photo_apres photo_chassis].include?(@document.type_document)
          limit_mb = is_photo_type ? 100 : 30
          filename = @document.file.filename.to_s if @document.file.attached?
          errors << "Le fichier '#{filename}' (#{file_size_mb} MB) dépasse la limite autorisée de #{limit_mb} MB. Veuillez réduire la taille du fichier ou le compresser."
        else
          filename = @document.file.filename.to_s if @document.file.attached?
          errors << "Erreur lors du téléchargement du fichier '#{filename}': #{e.message}"
        end
      rescue => e
        errors << "Erreur inattendue lors du téléchargement: #{e.message}"
      end
    end

    # Réponse basée sur le succès/échec
    if errors.empty? && created_documents.any?
      # Envoyer une notification par email à l'administrateur (synchrone pour garantir la livraison)
      begin
        AdminMailer.document_uploaded(
          current_user,
          created_documents,
          {
            property: @property,
            project: @project,
            request: @request,
            simulation: @simulation
          }
        ).deliver_now
      rescue => e
        Rails.logger.error "[AdminMailer] ÉCHEC notification document_uploaded (user:#{current_user.id}): #{e.class} — #{e.message}"
        # On continue même si l'email échoue
      end

      # Si upload via AJAX
      if request.xhr?
        render json: {
          status: 'success',
          documents: created_documents.map { |doc| document_json(doc) },
          message: "#{created_documents.size} document(s) uploadé(s) avec succès",
          redirect_url: documents_path
        }
      else
        flash[:next_action] = next_action_after_document_upload(created_documents.last)
        redirect_to_context_or_default(notice: "#{created_documents.size} document(s) ajouté(s) avec succès")
      end
    else
      if request.xhr?
        render json: {
          status: 'error',
          errors: errors.presence || ['Aucun fichier valide uploadé']
        }, status: :unprocessable_entity
      else
        @document = current_user.documents.build(document_params.except(:file))
        flash.now[:alert] = errors.join(', ')
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

  # GET /documents/photos — Galerie photos de suivi (sidebar section 6)
  def photos
    photo_types = %w[photo_avant photo_pendant photo_apres photo_chassis]
    all_photos = current_user.documents
                             .where(type_document: photo_types)
                             .includes(:project, :property)
                             .order(created_at: :desc)

    # Grouper par projet, puis par photos sans projet
    @photos_by_project = all_photos.select(&:project_id).group_by(&:project)
    @photos_no_project = all_photos.reject(&:project_id)
    @total_photos = all_photos.size
  end

  # GET /documents/download_zip?project_id=X&type_document=photo_pendant
  # Génère un ZIP via l'API Cloudinary (pas de téléchargement sur le dyno)
  def download_zip
    photo_types = %w[photo_avant photo_pendant photo_apres photo_chassis]
    requested_types = Array(params[:type_document]).flatten.select { |t| photo_types.include?(t) }

    if requested_types.empty?
      redirect_back fallback_location: documents_path, alert: "Type de document non valide."
      return
    end

    unless @project
      redirect_back fallback_location: documents_path, alert: "Projet non spécifié."
      return
    end

    documents = @project.documents
                        .where(type_document: requested_types)
                        .order(created_at: :asc)
                        .select { |d| d.file.attached? && d.file.service_name.to_s.include?('cloudinary') }

    if documents.empty?
      redirect_back fallback_location: project_documents_path(@project, type_document: params[:type_document]),
                    alert: "Aucune photo disponible au téléchargement."
      return
    end

    public_ids = documents.filter_map do |doc|
      # Extraire le public_id réel depuis l'URL Cloudinary
      # URL: .../upload/v1/production/KEY.EXT → public_id = production/KEY
      url = doc.file.url.to_s.split('?').first
      url.match(%r{/upload/v?\d*/(.+?)(?:\.[^./]+)?$})&.send(:[], 1)
    end
    type_label  = requested_types.size == 1 ? requested_types.first : "photos"
    archive_name = "#{@project.nom.parameterize}_#{type_label}_#{Date.today.iso8601}"

    zip_url = Cloudinary::Utils.download_zip_url(
      public_ids: public_ids,
      resource_type: "image",
      target_public_id: archive_name
    )

    redirect_to zip_url, allow_other_host: true
  rescue ActiveRecord::RecordNotFound
    redirect_to documents_path, alert: "Projet non trouvé."
  end

  # GET /documents/:id/download
  def download
    Rails.logger.info "⬇️ DEBUT download pour document ID: #{params[:id]}"

    unless can_access_document?(@document)
      Rails.logger.warn "❌ Accès refusé pour document #{@document&.id} par user #{current_user&.id}"
      redirect_to root_path, alert: "Accès non autorisé"
      return
    end

    # Déterminer la disposition : inline pour visualisation, attachment pour téléchargement
    disposition = params[:disposition] == 'inline' ? 'inline' : 'attachment'
    Rails.logger.info "⬇️ Download demandé pour document #{@document.id} (#{@document.file.content_type}) avec disposition: #{disposition}"

    if @document.file.attached?
      # Récupérer le nom original du fichier
      original_filename = @document.file.filename.to_s

      Rails.logger.info "📥 Envoi du fichier avec nom original: #{original_filename}"

      begin
        # Toujours télécharger le fichier et l'envoyer avec le nom original
        # pour avoir un contrôle complet sur le nom de fichier
        file_data = @document.file.download
        send_data file_data,
                  filename: original_filename,
                  type: @document.file.content_type,
                  disposition: disposition
        Rails.logger.info "✅ Fichier envoyé avec succès: #{original_filename} (#{disposition})"
      rescue => e
        Rails.logger.error "❌ Erreur téléchargement: #{e.message}"
        redirect_back(fallback_location: root_path, alert: "Erreur lors du téléchargement")
      end
    elsif @document.file_url.present? && safe_external_url?(@document.file_url)
      redirect_to @document.file_url, allow_other_host: true
    elsif @document.file_url.present?
      redirect_back(fallback_location: root_path, alert: "URL de fichier non autorisée")
    else
      redirect_back(fallback_location: root_path, alert: "Fichier non trouvé")
    end
  end

  # GET /documents/:id/preview
  def preview
    Rails.logger.info "🎬 DEBUT preview pour document ID: #{params[:id]}"

    unless can_access_document?(@document)
      Rails.logger.warn "❌ Accès refusé pour document #{@document&.id} par user #{current_user&.id}"
      render json: { error: "Accès non autorisé" }, status: :forbidden
      return
    end

    if @document.file.attached?
      begin
        Rails.logger.info "🔍 Preview demandée pour document #{@document.id} (#{@document.file.content_type})"

        if @document.is_image?
          url = @document.cloudinary_url || rails_blob_url(@document.file)
          Rails.logger.info "🖼️ URL image générée: #{url}"
          render json: {
            type: 'image',
            url: url,
            filename: @document.file_name
          }
        elsif @document.is_pdf?
          # Utiliser directement l'URL Cloudinary corrigée
          pdf_url = @document.cloudinary_url
          preview_url = @document.cloudinary_preview_url

          Rails.logger.info "📄 URLs PDF - Principal: #{pdf_url}"
          Rails.logger.info "📄 URLs PDF - Preview: #{preview_url}"

          render json: {
            type: 'pdf',
            url: pdf_url || rails_blob_url(@document.file),
            preview_url: preview_url,
            filename: @document.file_name
          }
        else
          render json: {
            type: 'unsupported',
            message: 'Prévisualisation non disponible pour ce type de fichier',
            download_url: download_document_url(@document)
          }
        end
      rescue => e
        Rails.logger.error "❌ Erreur preview document #{@document.id}: #{e.message}"
        render json: {
          error: "Erreur lors de la génération de la prévisualisation",
          debug_info: {
            content_type: @document.file.content_type,
            service: @document.file.service_name,
            size: @document.file.byte_size,
            key: @document.file.key,
            error: e.message
          }
        }, status: :internal_server_error
      end
    else
      render json: { error: "Fichier non trouvé" }, status: :not_found
    end
  end

  # GET /documents/:id/debug - Diagnostic du fichier
  def debug
    unless can_access_document?(@document)
      render json: { error: "Accès non autorisé" }, status: :forbidden
      return
    end

    if @document.file.attached?
      begin
        file_data = @document.file.download

        # Informations de diagnostic
        debug_info = {
          filename: @document.file.filename.to_s,
          content_type: @document.file.content_type,
          byte_size: @document.file.byte_size,
          downloaded_size: file_data.bytesize,
          file_url: @document.file_url,
          cloudinary_key: @document.file.key,
          service_name: @document.file.service_name,
          is_pdf: file_data.start_with?('%PDF'),
          first_bytes: file_data[0..20].bytes.map(&:chr).join.inspect,
          last_bytes: file_data[-20..-1]&.bytes&.map(&:chr)&.join&.inspect
        }

        render json: debug_info
      rescue => e
        render json: { error: e.message, backtrace: e.backtrace.first(5) }
      end
    else
      render json: { error: "Aucun fichier attaché" }
    end
  end
  def view
    unless can_access_document?(@document)
      redirect_to root_path, alert: "Accès non autorisé"
      return
    end

    if @document.file.attached?
      # Utiliser notre action download avec disposition inline pour garder le nom de fichier
      redirect_to download_document_path(@document, disposition: 'inline'), allow_other_host: true
    elsif @document.file_url.present? && safe_external_url?(@document.file_url)
      redirect_to @document.file_url, allow_other_host: true
    elsif @document.file_url.present?
      redirect_back(fallback_location: root_path, alert: "URL de fichier non autorisée")
    else
      redirect_back(fallback_location: root_path, alert: "Aucun fichier associé à ce document")
    end
  end

  # GET /documents/:id/ocr_view
  def ocr_view
    unless can_access_document?(@document)
      redirect_to root_path, alert: "Accès non autorisé"
      return
    end

    unless @document.has_ocr_content?
      redirect_to document_path(@document), alert: "Ce document ne contient pas de contenu OCR"
      return
    end

    # Variables pour la vue
    @ocr_content = @document.ocr_content
    @ocr_confidence = @document.ocr_confidence
    @ocr_language = @document.ocr_language
    @ocr_method = @document.ocr_method
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
  rescue ActiveRecord::RecordNotFound
    redirect_to documents_path, alert: "Document non trouvé"
  end

  def set_context
    # Détecter le contexte depuis les paramètres
    @property = current_user.properties.find(params[:property_id]) if params[:property_id]
    @project = current_user.projects.find(params[:project_id]) if params[:project_id]
    # Propager @property depuis @project si non fourni explicitement
    @property ||= @project.property if @project&.property
    @request = current_user.requests.find(params[:request_id]) if params[:request_id]
    @simulation = current_user.simulations.find(params[:simulation_id]) if params[:simulation_id]
  end

  def document_params
    params.require(:document).permit(:type_document, :status, :document_source, :file, :file_url, :notes, :property_id, :project_id, :request_id, :simulation_id)
  end

  def can_access_document?(document)
    return false if document.nil?
    return false if current_user.nil?

    # Vérification que l'utilisateur peut accéder au document
    # 1. Document appartient directement à l'utilisateur
    return true if document.user_id == current_user.id

    # 2. Document lié à une propriété de l'utilisateur
    return true if document.property&.user_id == current_user.id

    # 3. Document lié à un projet de l'utilisateur
    return true if document.project&.user_id == current_user.id

    # 4. Document lié à une simulation de l'utilisateur
    return true if document.simulation&.user_id == current_user.id

    false
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

  def next_action_after_document_upload(document)
    return nil unless document
    project = document.project || @project

    case document.type_document
    when 'facture'
      if project
        "Facture enregistrée. <strong>Prochaine étape :</strong> vérifiez les données extraites et validez la facture. " \
        "<a href=\"#{project_factures_path(project)}\" class=\"alert-link\">Voir les factures →</a>"
      else
        "Facture enregistrée. Associez-la à un projet pour suivre votre budget."
      end
    when 'devis'
      if project
        "Devis ajouté. <strong>Prochaine étape :</strong> comparez les devis et sélectionnez votre entrepreneur. " \
        "<a href=\"#{project_path(project)}\" class=\"alert-link\">Voir le projet →</a>"
      else
        "Devis ajouté. Associez-le à un projet pour démarrer le suivi."
      end
    when 'pv_reception', 'attestation_conformite'
      if project
        "Document de réception ajouté. <strong>Prochaine étape :</strong> clôturez la réception de chantier. " \
        "<a href=\"#{reception_chantier_project_path(project)}\" class=\"alert-link\">Réception de chantier →</a>"
      end
    when 'photo_avant', 'photo_pendant', 'photo_apres'
      labels = { 'photo_avant' => 'avant travaux', 'photo_pendant' => 'en cours', 'photo_apres' => 'après travaux' }
      "Photo #{labels[document.type_document]} enregistrée. Ces photos documentent l'avancement et facilitent les démarches de primes."
    when 'aer'
      "Attestation de revenu ajoutée — document requis pour les primes Wallonie et Flandre. " \
      "Ren0chat peut vous aider à vérifier votre éligibilité."
    else
      if project
        "Document ajouté. <strong>Consultez votre score de santé</strong> pour voir l'impact sur votre dossier. " \
        "<a href=\"#{score_sante_project_path(project)}\" class=\"alert-link\">Score de santé →</a>"
      end
    end
  end

  def redirect_to_context_or_default(options = {})
    # Contextes nommés sûrs (pas d'open redirect)
    if params[:return_context].present? && @project
      case params[:return_context]
      when 'budget'
        redirect_to edit_budget_project_path(@project), options
        return
      when 'reception_chantier'
        redirect_to reception_chantier_project_path(@project), options
        return
      when 'garanties'
        redirect_to garanties_project_path(@project), options
        return
      when 'carnet_entretien'
        redirect_to carnet_entretien_project_path(@project), options
        return
      end
    end

    # Redirection via return_to (URL absolue sûre — seulement vers nos routes connues)
    if params[:return_to].present? && @project
      allowed_paths = [
        garanties_project_path(@project),
        carnet_entretien_project_path(@project),
        reception_chantier_project_path(@project)
      ]
      if allowed_paths.include?(params[:return_to])
        redirect_to params[:return_to], options
        return
      end
    end

    # Préserver les paramètres de filtrage
    redirect_params = {}
    redirect_params[:type_document] = params[:type_document] if params[:type_document].present?
    redirect_params[:filter_phase] = params[:filter_phase] if params[:filter_phase].present?

    photo_types = %w[photo photo_avant photo_pendant photo_apres photo_chassis]
    came_from_photo_upload = photo_types.include?(params.dig(:document, :type_document))

    # Récupérer le contexte depuis le document lui-même si non défini (ex: destroy)
    @project  ||= @document&.project
    @property ||= @document&.property

    if @project
      # Après suppression ou upload photo → retour sur la fiche projet (widget photos)
      if came_from_photo_upload || photo_types.include?(@document&.type_document)
        redirect_to project_path(@project), options
      else
        redirect_to project_documents_path(@project, redirect_params), options
      end
    elsif @property
      redirect_to property_documents_path(@property, redirect_params), options
    else
      redirect_to documents_path(redirect_params), options
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

  def build_ocr_notes(ocr_result)
    if ocr_result[:confidence] > 0
      "📄 Texte extrait par OCR (#{ocr_result[:method]}):\n" \
      "Confiance: #{ocr_result[:confidence]}%\n" \
      "Langue: #{ocr_result[:language]}\n" \
      "Temps de traitement: #{ocr_result[:processing_time]}s\n\n" \
      "#{ocr_result[:text]}"
    else
      "📄 Document scanné (OCR non disponible)\n" \
      "Méthode: #{ocr_result[:method]}\n\n" \
      "#{ocr_result[:text]}"
    end
  end

  # Crée un enregistrement Facture à partir des données OCR extraites
  # lors d'un upload via DocumentsController (hors workflow FacturesController)
  def creer_facture_depuis_ocr_doc(document, ocr_result, project)
    donnees = ocr_result[:donnees_facture]

    facture = Facture.new(
      document: document,
      project: project,
      property: document.property || project.property,
      montant: donnees[:montant] || 0,
      numero_facture: donnees[:numero_facture],
      date_facture: donnees[:date_facture],
      type_facture: donnees[:type_facture] || 'facture',
      statut_paiement: 'non_paye',
      nom_entreprise: donnees[:nom_entreprise],
      numero_bce_entreprise: donnees[:numero_bce],
      montant_ht: donnees[:montant_ht],
      montant_tva: donnees[:montant_tva],
      taux_tva: donnees[:taux_tva],
      confiance_ocr: ocr_result[:confiance_extraction],
      extraction_complete: ocr_result[:extraction_complete],
      texte_ocr_brut: ocr_result[:texte_brut],
      donnees_extraites: donnees,
      type_intervenant: detecter_type_intervenant_doc(donnees[:nom_entreprise], project),
      valide_manuellement: false
    )

    if facture.save
      Rails.logger.info "Facture ##{facture.id} créée depuis OCR document ##{document.id} (projet ##{project.id})"
      facture
    else
      msg = facture.errors.full_messages.join(', ')
      Rails.logger.error "Échec création Facture depuis OCR document ##{document.id}: #{msg}"
      flash[:alert] = "Document uploadé, mais l'extraction budgétaire a échoué : #{msg}" if request.present?
      nil
    end
  rescue => e
    Rails.logger.error "Exception création Facture depuis OCR document ##{document.id}: #{e.message}\n#{e.backtrace.first(3).join('\n')}"
    nil
  end

  # Tente de détecter si la facture provient de l'architecte ou d'un entrepreneur
  def detecter_type_intervenant_doc(nom_entreprise, project)
    return 'entrepreneur' if nom_entreprise.blank?

    nom = nom_entreprise.downcase.strip
    arch = project.architecte_entreprise&.downcase&.strip
    return 'architecte' if arch.present? && nom.include?(arch.split.first || '')

    'entrepreneur'
  end
end
