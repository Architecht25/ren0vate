class CloudinaryPublicService < ActiveStorage::Service::CloudinaryService
  def url(key, **options)
    # Génère une URL publique sans signature pour les PDFs
    instrument :url, key: key do |payload|
      # Configuration Cloudinary
      cloud_name = @cloud_name || ENV['CLOUDINARY_CLOUD_NAME']
      folder = @folder || Rails.env

      # Détermine le type de ressource selon l'extension
      filename = options[:filename] || key
      extension = File.extname(filename.to_s).downcase

      # URL publique sans signature
      if extension == '.pdf'
        # Pour les PDFs, utilise resource_type raw
        public_url = "https://res.cloudinary.com/#{cloud_name}/raw/upload/v1/#{folder}/#{key}.pdf"
      else
        # Pour les autres fichiers, utilise resource_type image
        public_url = "https://res.cloudinary.com/#{cloud_name}/image/upload/v1/#{folder}/#{key}"
        public_url += extension if extension.present?
      end

      payload[:url] = public_url

      public_url
    end
  end

  private

  def instrument(operation, payload = {}, &block)
    ActiveSupport::Notifications.instrument(
      "service_#{operation}.active_storage",
      payload.merge(service: service_name), &block
    )
  end

  def service_name
    "Cloudinary Public"
  end
end
