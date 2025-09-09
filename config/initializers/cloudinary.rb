require 'cloudinary'

Cloudinary.config do |config|
  config.cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
  config.api_key = ENV['CLOUDINARY_API_KEY']
  config.api_secret = ENV['CLOUDINARY_API_SECRET']
  config.secure = Rails.env.production?
  config.cdn_subdomain = true
end

# Configuration spéciale pour Active Storage
if defined?(ActiveStorage)
  Rails.application.config.active_storage.variant_processor = :mini_magick

  # Désactiver les transformations automatiques pour certains types de fichiers
  Rails.application.config.after_initialize do
    ActiveStorage::Blob.class_eval do
      def content_type_for_serving
        # Forcer le content-type correct pour les PDFs
        if content_type == 'application/pdf'
          'application/pdf'
        else
          content_type
        end
      end
    end
  end
end
