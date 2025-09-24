class EmailDocumentExtractionJob < ApplicationJob
  queue_as :default

  def perform(request_progress_id, document_type)
    @request_progress = RequestProgress.find(request_progress_id)
    @document_type = document_type

    Rails.logger.info "🔍 Début extraction document #{document_type} pour RequestProgress ##{request_progress_id}"

    # Marquer comme en cours de traitement
    @request_progress.update!(document_extraction_status: 'processing')

    case document_type
    when 'pdf'
      extract_from_pdf
    when 'image'
      extract_from_image
    else
      Rails.logger.error "❌ Type de document non supporté: #{document_type}"
      @request_progress.mark_extraction_failed("Type de document non supporté: #{document_type}")
      return
    end

    Rails.logger.info "✅ Extraction terminée pour RequestProgress ##{request_progress_id}"
  end

  private

  def extract_from_pdf
    return unless @request_progress.document_suivi_pdf.attached?

    begin
      # Utiliser un service d'extraction PDF
      extracted_data = EmailDocumentExtractionService.new(@request_progress.document_suivi_pdf).extract_pdf_data

      # Mettre à jour le RequestProgress avec les données extraites
      update_request_progress_with_extracted_data(extracted_data)

    rescue => e
      Rails.logger.error "❌ Erreur lors de l'extraction PDF: #{e.message}"
      @request_progress.mark_extraction_failed("Erreur extraction PDF: #{e.message}")
    end
  end

  def extract_from_image
    return unless @request_progress.document_suivi_photo.attached?

    begin
      # Utiliser un service d'extraction d'image (OCR)
      extracted_data = EmailDocumentExtractionService.new(@request_progress.document_suivi_photo).extract_image_data

      # Mettre à jour le RequestProgress avec les données extraites
      update_request_progress_with_extracted_data(extracted_data)

    rescue => e
      Rails.logger.error "❌ Erreur lors de l'extraction d'image: #{e.message}"
      @request_progress.mark_extraction_failed("Erreur extraction image: #{e.message}")
    end
  end

  def update_request_progress_with_extracted_data(extracted_data)
    return if extracted_data.blank?

    update_params = {}

    # Mettre à jour le numéro de dossier si trouvé
    if extracted_data[:numero_dossier].present? && @request_progress.numero_dossier.blank?
      update_params[:numero_dossier] = extracted_data[:numero_dossier]
    end

    # Mettre à jour le montant accordé si trouvé
    if extracted_data[:montant_accorde].present?
      update_params[:montant_accorde] = extracted_data[:montant_accorde]
    end

    # Mettre à jour le statut si détecté
    if extracted_data[:status_administratif].present?
      update_params[:status_administratif] = extracted_data[:status_administratif]
    end

    # Ajouter les informations extraites aux commentaires
    if extracted_data[:extracted_text].present?
      extraction_comment = "\n--- Extraction automatique (#{@document_type}) ---\n"
      extraction_comment += extracted_data[:extracted_text]

      current_comments = @request_progress.commentaires_admin || ""
      update_params[:commentaires_admin] = current_comments + extraction_comment
    end

    # Mettre à jour la date de dernière modification
    update_params[:date_derniere_maj] = Date.current

    # Sauvegarder les données extraites et marquer comme terminé
    @request_progress.store_extracted_data(extracted_data) if extracted_data.any?
    @request_progress.update!(update_params) if update_params.any?

    Rails.logger.info "📝 RequestProgress ##{@request_progress.id} mis à jour avec: #{update_params.keys.join(', ')}"
  end
end
