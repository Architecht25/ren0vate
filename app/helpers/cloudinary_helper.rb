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

  # Génère l'URL d'image pour une prime spécifique basée sur son champ image
  def prime_specific_image_url(prime, transformations = {})
    return prime_card_image_url('default') unless prime&.image.present?

    # Mapping des types de primes vers leurs IDs Cloudinary spécifiques
    cloudinary_image_mapping = {
      # Isolation
      'isolation_toiture' => 'isolation_toiture_f9r4hs',
      'toiture' => 'isolation_toiture_f9r4hs',
      'isolation_murs' => 'isolation_murs_ext_ahbpat',
      'murs' => 'isolation_murs_ext_ahbpat',
      'isolation_sol' => 'isolation_sol_kokpgs',
      'sol' => 'isolation_sol_kokpgs',
      'plancher' => 'isolation_sol_kokpgs',

      # Chauffage et énergie
      'pac' => 'pac_géothermique_cj7l2y',
      'pompe_chaleur' => 'pac_géothermique_cj7l2y',
      'chauffage' => 'pac_géothermique_cj7l2y',
      'pac_hybride' => 'pac_hybride_ukmzp8',
      'solaire' => 'aurostep-plus-avec-capteurs-solaire-389237-format-flex-height_yzlwxc',

      # Ouvertures
      'chassis' => 'remplacement_chassis_lrszxo',
      'fenetre' => 'remplacement_chassis_lrszxo',
      'porte' => 'remplacement_chassis_lrszxo',

      # Ventilation
      'ventilation' => 'Housing-Ventilation-Shutterstock-16-9-1920x1080px_uxckrq',

      # Rénovation
      'renovation_toiture' => 'renovation_toiture_guwknw',
      'renovation_murs' => 'Prix-enduit-m2-interieur_ihdtjp',
      'renovation_sol' => 'renovation_sol_nswlc0',
      'efficacite' => 'efficacite-energetique-batiment_mlgdaj',

      # Divers
      'eau' => '30953015-deplacement-arrivee-eau-evacuation-eau_hkgieu',
      'isolation_exterieur' => 'ibt-art-isolation-exterieur-2000x800-compressed_owmg5m'
    }

    # Déterminer l'ID Cloudinary basé sur le titre ou slug de la prime
    cloudinary_id = determine_cloudinary_id(prime, cloudinary_image_mapping)

    default_transformations = {
      width: 80,
      height: 80,
      crop: 'fill',
      quality: 'auto:good',
      format: 'auto'
    }

    cloudinary_url(cloudinary_id, default_transformations.merge(transformations))
  end

  private

  def determine_cloudinary_id(prime, mapping)
    title_lower = prime.titre.downcase
    slug_lower = prime.slug.downcase if prime.respond_to?(:slug)

    # Rechercher par mots-clés dans le titre et slug
    mapping.each do |keyword, cloudinary_id|
      if title_lower.include?(keyword) || (slug_lower && slug_lower.include?(keyword))
        return cloudinary_id
      end
    end

    # Image par défaut si aucune correspondance
    'efficacite-energetique-batiment_mlgdaj'
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
