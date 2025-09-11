# Helper pour les images statiques Cloudinary
module CloudinaryHelper
  # Images des primes par catégorie
  PRIME_IMAGES = {
    'isolation' => 'static/primes/isolation.jpg',
    'chauffage' => 'static/primes/chauffage.jpg',
    'ventilation' => 'static/primes/ventilation.jpg',
    'energie_renouvelable' => 'static/primes/solaire.jpg',
    'audit_energetique' => 'static/primes/audit.jpg',
    'toiture' => 'static/primes/toiture.jpg',
    'fenetre' => 'static/primes/fenetres.jpg',
    'default' => 'static/primes/renovation.jpg'
  }.freeze

  # Génère l'URL Cloudinary optimisée pour une prime
  def prime_image_url(prime_or_category, transformations = {})
    category = prime_or_category.is_a?(String) ? prime_or_category : prime_or_category&.category
    image_path = PRIME_IMAGES[category] || PRIME_IMAGES['default']

    default_transformations = {
      width: 300,
      height: 200,
      crop: 'fill',
      quality: 'auto:good',
      format: 'auto'
    }

    cloudinary_url(image_path, default_transformations.merge(transformations))
  end

  # Pour les cartes de primes (plus petites)
  def prime_card_image_url(prime_or_category)
    prime_image_url(prime_or_category, {
      width: 200,
      height: 120,
      crop: 'fill'
    })
  end

  # Pour les headers de pages (plus grandes)
  def prime_hero_image_url(prime_or_category)
    prime_image_url(prime_or_category, {
      width: 800,
      height: 300,
      crop: 'fill'
    })
  end

  private

  def cloudinary_url(path, transformations = {})
    return "#" unless Rails.env.production? || Rails.env.staging?

    base_url = "https://res.cloudinary.com/#{ENV['CLOUDINARY_CLOUD_NAME']}/image/upload"

    if transformations.any?
      transform_string = transformations.map { |k, v| "#{k}_#{v}" }.join(',')
      "#{base_url}/#{transform_string}/#{path}"
    else
      "#{base_url}/#{path}"
    end
  end
end
