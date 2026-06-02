class CloudinaryPdfService
  class << self
    def upload_pdf(file_path, options = {})
      default_options = {
        resource_type: :raw,  # Important pour les PDFs
        use_filename: true,
        unique_filename: true,  # Éviter les conflits
        invalidate: true,
        tags: ['pdf', 'document']
      }

      Cloudinary::Uploader.upload(file_path, default_options.merge(options))
    end

    def generate_pdf_url(public_id, options = {})
      inline   = options.delete(:inline)
      filename = options.delete(:filename)

      default_options = {
        resource_type: :raw,  # CORRECT: Utiliser :raw pour les PDFs comme à l'upload !
        secure: true,  # Forcer HTTPS même en développement
        sign_url: false  # URLs publiques pour les PDFs
      }

      # Ajouter le flag 'attachment' uniquement pour le téléchargement, pas pour la vue inline
      unless inline
        default_options[:flags] = filename.present? ? "attachment:#{filename}" : 'attachment'
      end

      begin
        url = Cloudinary::Utils.cloudinary_url(public_id, default_options.merge(options))
        Rails.logger.info "🔗 URL PDF générée (#{inline ? 'inline' : 'attachment'}) avec resource_type: raw - #{url}"
        url
      rescue => e
        Rails.logger.error "❌ Erreur génération URL PDF pour #{public_id}: #{e.message}"
        nil
      end
    end

    def generate_preview_url(public_id, options = {})
      # Pour les PDFs, on peut générer une image de la première page
      # Utiliser resource_type image car nous générons une image depuis un PDF
      default_options = {
        resource_type: :image,  # Changé d'auto à image car le résultat est une image
        format: :jpg,
        transformation: [
          { page: 1 },  # Première page
          { width: 400, height: 600, crop: :fit }
        ],
        secure: true  # Forcer HTTPS même en développement pour éviter les problèmes CSP
      }

      begin
        url = Cloudinary::Utils.cloudinary_url(public_id, default_options.merge(options))
        Rails.logger.info "🖼️  Preview PDF générée: #{url}"
        url
      rescue => e
        Rails.logger.warn "Could not generate PDF preview for #{public_id}: #{e.message}"
        nil
      end
    end

    def pdf_info(public_id)
      begin
        Cloudinary::Api.resource(public_id, resource_type: :raw)
      rescue Cloudinary::Api::NotFound
        nil
      rescue => e
        Rails.logger.error "Error fetching PDF info for #{public_id}: #{e.message}"
        nil
      end
    end
  end
end
