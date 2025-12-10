class Api::PdfPreviewController < ApplicationController
  before_action :authenticate_user!

  def generate
    document = current_user.documents.find(params[:id])

    if document.is_pdf?
      # Génération asynchrone de l'aperçu
      preview_url = PdfPreviewService.generate_preview_for_document(document)

      if preview_url
        render json: {
          success: true,
          preview_url: preview_url,
          document_id: document.id
        }
      else
        render json: {
          success: false,
          error: "Impossible de générer l'aperçu PDF",
          document_id: document.id
        }, status: 422
      end
    else
      render json: {
        success: false,
        error: "Le document n'est pas un PDF",
        document_id: document.id
      }, status: 400
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      error: "Document non trouvé"
    }, status: 404
  rescue => e
    Rails.logger.error "Erreur génération aperçu PDF: #{e.message}"
    render json: {
      success: false,
      error: "Erreur serveur",
      document_id: params[:id]
    }, status: 500
  end
end
