class PdfPreviewService
  class << self
    def generate_preview_for_document(document)
      return nil unless document&.file&.attached?
      return nil unless document.is_pdf?
      return nil unless document.file.service_name.to_s == 'cloudinary'

      # Vérifier si l'aperçu existe déjà en cache
      cache_key = "pdf_preview_#{document.id}_#{document.file.blob.checksum}"

      Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        begin
          # Télécharger temporairement le PDF depuis Active Storage
          temp_file = download_pdf_from_active_storage(document)

          if temp_file
            # Upload du PDF sur Cloudinary avec resource_type auto pour permettre transformations
            cloudinary_result = upload_to_cloudinary_for_preview(temp_file, document)

            if cloudinary_result
              # Générer l'URL d'aperçu avec la transformation page 1
              preview_url = CloudinaryPdfService.generate_preview_url(cloudinary_result['public_id'])
              Rails.logger.info "🖼️ Aperçu PDF généré pour document #{document.id}: #{preview_url}"
              preview_url
            end
          end
        rescue => e
          Rails.logger.error "❌ Erreur génération aperçu PDF pour document #{document.id}: #{e.message}"
          nil
        ensure
          # Nettoyer le fichier temporaire
          temp_file&.close
          temp_file&.unlink if temp_file&.path
        end
      end
    end

    private

    def download_pdf_from_active_storage(document)
      # Créer un fichier temporaire
      temp_file = Tempfile.new(['pdf_preview', '.pdf'])
      temp_file.binmode

      # Télécharger le contenu depuis Active Storage
      document.file.blob.download do |chunk|
        temp_file.write(chunk)
      end

      temp_file.rewind
      temp_file
    rescue => e
      Rails.logger.error "❌ Erreur téléchargement PDF: #{e.message}"
      temp_file&.close
      temp_file&.unlink if temp_file&.path
      nil
    end

    def upload_to_cloudinary_for_preview(temp_file, document)
      # Upload avec un public_id simple basé sur l'ID du document
      public_id = "pdf_previews/doc_#{document.id}_#{SecureRandom.hex(8)}"

      result = Cloudinary::Uploader.upload(
        temp_file.path,
        public_id: public_id,
        resource_type: :auto, # Important pour permettre les transformations PDF
        overwrite: true, # Remplacer si existe déjà
        invalidate: true,
        tags: ['pdf_preview', "doc_#{document.id}"]
      )

      Rails.logger.info "📤 PDF uploadé sur Cloudinary: #{result['public_id']}"
      result
    rescue => e
      Rails.logger.error "❌ Erreur upload Cloudinary: #{e.message}"
      nil
    end
  end
end
