class OcrController < ApplicationController
  before_action :authenticate_user!

  # POST /ocr/scan
  def scan
    return render json: { error: 'Aucun fichier fourni' }, status: :bad_request unless params[:file]

    begin
      ocr_service = OcrService.new(params[:file])
      result = ocr_service.call

      if result[:success]
        render json: {
          success: true,
          text: result[:text],
          confidence: result[:confidence],
          language: result[:language],
          processing_time: result[:processing_time],
          method: result[:method]
        }
      else
        render json: {
          error: result[:error]
        }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Erreur OCR: #{e.message}"
      render json: {
        error: 'Erreur lors du traitement OCR',
        details: Rails.env.development? ? e.message : nil
      }, status: :internal_server_error
    end
  end

  # POST /ocr/scan_and_create_document
  def scan_and_create_document
    return render json: { error: 'Aucun fichier fourni' }, status: :bad_request unless params[:file]

    begin
      # Effectuer l'OCR d'abord
      ocr_service = OcrService.new(params[:file])
      ocr_result = ocr_service.call

      unless ocr_result[:success]
        return render json: { error: ocr_result[:error] }, status: :unprocessable_entity
      end

      # Créer le document avec le texte OCR dans les notes
      document_params = build_document_params(ocr_result)
      @document = current_user.documents.build(document_params)

      if @document.save
        # Générer file_url après la sauvegarde
        if @document.file.attached? && @document.file_url.blank?
          @document.update(file_url: rails_blob_url(@document.file))
        end

        render json: {
          success: true,
          document: document_json(@document),
          ocr: {
            text: ocr_result[:text],
            confidence: ocr_result[:confidence],
            language: ocr_result[:language],
            method: ocr_result[:method]
          },
          message: 'Document créé avec succès et texte extrait par OCR'
        }
      else
        render json: {
          error: 'Erreur lors de la création du document',
          details: @document.errors.full_messages
        }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Erreur OCR + Document: #{e.message}"
      render json: {
        error: 'Erreur lors du traitement',
        details: Rails.env.development? ? e.message : nil
      }, status: :internal_server_error
    end
  end

  # POST /ocr/scan_existing/:id
  def scan_existing
    @document = current_user.documents.find(params[:id])

    unless @document.file.attached?
      return render json: { error: 'Ce document ne possède pas de fichier attaché' }, status: :unprocessable_entity
    end

    begin
      # Télécharger le fichier depuis ActiveStorage dans un Tempfile
      tempfile = Tempfile.new(['ocr_existing', File.extname(@document.file.filename.to_s)])
      tempfile.binmode
      tempfile.write(@document.file.download)
      tempfile.rewind

      # Construire un objet compatible OcrService
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: @document.file.filename.to_s,
        type: @document.file.content_type
      )

      ocr_service = OcrService.new(uploaded_file)
      result = ocr_service.call

      if result[:success]
        # Mettre à jour les notes du document avec le résultat OCR
        ocr_notes = "📄 Texte extrait par OCR (#{result[:method]}):\n" \
                    "Confiance: #{result[:confidence]}%\n" \
                    "Langue: #{result[:language]}\n" \
                    "Temps de traitement: #{result[:processing_time]}s\n\n" \
                    "#{result[:text]}"

        existing_notes = @document.notes.to_s.sub(/📄 Texte extrait par OCR.*\z/m, '').strip
        new_notes = [existing_notes.presence, ocr_notes].compact.join("\n\n")
        @document.update!(notes: new_notes)

        render json: {
          success: true,
          document_id: @document.id,
          text: result[:text],
          confidence: result[:confidence],
          language: result[:language],
          processing_time: result[:processing_time],
          method: result[:method]
        }
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Document introuvable' }, status: :not_found
    rescue StandardError => e
      Rails.logger.error "OCR scan_existing error: #{e.message}"
      render json: {
        error: 'Erreur lors du traitement OCR',
        details: Rails.env.development? ? e.message : nil
      }, status: :internal_server_error
    ensure
      tempfile&.close
      tempfile&.unlink
    end
  end

  private

  def build_document_params(ocr_result)
    # Construire les notes avec le texte OCR
    ocr_notes = if ocr_result[:confidence] > 0
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

    document_params = {
      file: params[:file],
      type_document: params[:type_document] || 'facture',
      notes: ocr_notes,
      status: 'pending'
    }

    # Associer à un contexte si fourni
    document_params[:property_id] = params[:property_id] if params[:property_id].present?
    document_params[:project_id] = params[:project_id] if params[:project_id].present?
    document_params[:request_id] = params[:request_id] if params[:request_id].present?
    document_params[:simulation_id] = params[:simulation_id] if params[:simulation_id].present?

    document_params
  end

  def document_json(document)
    {
      id: document.id,
      type_document: document.type_document,
      filename: document.file.filename.to_s,
      file_size: document.file.byte_size,
      notes: document.notes,
      status: document.status,
      created_at: document.created_at.strftime("%d/%m/%Y %H:%M"),
      file_url: document.file_url
    }
  end
end
