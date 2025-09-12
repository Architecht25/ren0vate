class CloudinaryPublicService < ActiveStorage::Service
  def initialize(**config)
    @cloud_name = config[:cloud_name] || ENV['CLOUDINARY_CLOUD_NAME']
    @api_key = config[:api_key] || ENV['CLOUDINARY_API_KEY']
    @api_secret = config[:api_secret] || ENV['CLOUDINARY_API_SECRET']
    @folder = config[:folder] || Rails.env
  end

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

  # Méthodes obligatoires pour ActiveStorage::Service (stubs)
  def upload(key, io, checksum: nil, **options)
    # Non implémenté - service en lecture seule
    raise NotImplementedError, "CloudinaryPublicService est en lecture seule"
  end

  def download(key, &block)
    # Non implémenté - utilise les URLs publiques
    raise NotImplementedError, "Utilisez url() pour accéder aux fichiers"
  end

  def download_chunk(key, range)
    # Non implémenté
    raise NotImplementedError, "Utilisez url() pour accéder aux fichiers"
  end

  def delete(key)
    # Non implémenté - service en lecture seule
    raise NotImplementedError, "CloudinaryPublicService est en lecture seule"
  end

  def delete_prefixed(prefix)
    # Non implémenté - service en lecture seule
    raise NotImplementedError, "CloudinaryPublicService est en lecture seule"
  end

  def exist?(key)
    # Implémentation basique - assume que le fichier existe
    true
  end
end
