class CloudinaryPdfService
  class << self
    def upload_pdf(file_path, options = {})
      default_options = {
        resource_type: :raw,  # Important pour les PDFs
        format: :pdf,
        use_filename: true,
        unique_filename: false,
        invalidate: true,
        tags: ['pdf', 'document']
      }

      Cloudinary::Uploader.upload(file_path, default_options.merge(options))
    end

    def generate_pdf_url(public_id, options = {})
      default_options = {
        resource_type: :raw,
        format: :pdf,
        secure: Rails.env.production?,
        sign_url: true  # Important pour l'authentification
      }

      Cloudinary::Utils.cloudinary_url(public_id, default_options.merge(options))
    end

    def generate_preview_url(public_id, options = {})
      # Pour les PDFs, on peut générer une image de la première page
      default_options = {
        resource_type: :image,  # Important: pas raw pour la preview
        format: :jpg,
        transformation: [
          { page: 1 },  # Première page
          { width: 400, height: 600, crop: :fit },
          { quality: :auto }
        ],
        secure: Rails.env.production?
      }

      begin
        Cloudinary::Utils.cloudinary_url(public_id, default_options.merge(options))
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
