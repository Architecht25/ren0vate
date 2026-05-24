module SeoHelper
  # Méthode pour définir toutes les métadonnées SEO d'une page
  def set_seo_meta(title: nil, description: nil, keywords: nil, canonical_url: nil,
                   og_title: nil, og_description: nil, og_image: nil,
                   twitter_title: nil, twitter_description: nil, twitter_image: nil)

    content_for(:title, title) if title
    content_for(:meta_description, description) if description
    content_for(:keywords, keywords) if keywords
    content_for(:canonical_url, canonical_url) if canonical_url

    # Open Graph
    content_for(:og_title, og_title || title) if og_title || title
    content_for(:og_description, og_description || description) if og_description || description
    content_for(:og_image, og_image) if og_image
    content_for(:og_url, canonical_url || request.original_url)

    # Twitter
    content_for(:twitter_title, twitter_title || og_title || title) if twitter_title || og_title || title
    content_for(:twitter_description, twitter_description || og_description || description) if twitter_description || og_description || description
    content_for(:twitter_image, twitter_image || og_image) if twitter_image || og_image
  end

  # Générer l'URL canonique pour une page avec support multi-langue
  def canonical_url_for(path, locale: I18n.locale)
    base_url = Rails.application.config.force_ssl ? "https://" : "http://"
    base_url += request.host_with_port

    if locale.to_s != I18n.default_locale.to_s
      "#{base_url}/#{locale}#{path}"
    else
      "#{base_url}#{path}"
    end
  end

  # Métadonnées spécifiques par région
  def region_seo_data(region)
    case region.to_s.downcase
    when 'flandre'
      {
        title: "Primes Rénovation Flandre - Calculateur d'Aides Énergétiques",
        description: "Calculez vos primes à la rénovation en Flandre. Simulation gratuite pour isolation, chauffage, toiture et plus. Testez votre éligibilité en 2 minutes.",
        keywords: "primes flandre, rénovation flandre, isolation flandre, aides énergétiques flandre, VEKA primes"
      }
    when 'bruxelles'
      {
        title: "Primes Rénovation Bruxelles - Aides et Subventions Région Bruxelloise",
        description: "Découvrez toutes les primes à la rénovation à Bruxelles. Simulateur gratuit et personnalisé. Isolation, chauffage, audit énergétique.",
        keywords: "primes bruxelles, rénovation bruxelles, aides région bruxelloise, isolation bruxelles"
      }
    when 'wallonie'
      {
        title: "Primes Rénovation Wallonie - Calculateur Aides Énergétiques",
        description: "Estimez vos primes à la rénovation en Wallonie. Simulation gratuite et personnalisée selon vos revenus. Isolation, chauffage, ventilation.",
        keywords: "primes wallonie, rénovation wallonie, aides énergétiques wallonie, isolation wallonie, chauffage wallonie"
      }
    else
      {
        title: "Ren0vate — Passeport numérique de votre logement en Belgique",
        description: "Rénovation, primes, DIU, vente et gestion locative : Ren0vate centralise toute la vie de votre bien immobilier, en un seul endroit, pour propriétaires belges.",
        keywords: "gestion immobilière belgique, passeport logement, DIU, rénovation belgique, gestion locative, vente immobilière, primes, flandre, bruxelles, wallonie"
      }
    end
  end

  # Données structurées JSON-LD pour Schema.org
  def structured_data_organization
    {
      "@context": "https://schema.org",
      "@type": "Organization",
      "name": "Ren0vate",
      "url": canonical_url_for("/"),
      "logo": "#{request.protocol}#{request.host_with_port}/icon.png",
      "description": "Plateforme digitale de gestion immobilière en Belgique — rénovation, DIU, vente, location",
      "address": {
        "@type": "PostalAddress",
        "addressCountry": "BE"
      },
      "areaServed": [
        {
          "@type": "Country",
          "name": "Belgium"
        }
      ],
      "serviceType": [
        "Gestion immobilière digitale",
        "Passeport numérique du logement",
        "Gestion de chantiers de rénovation",
        "Dossier d'Intervention Ultérieure (DIU)",
        "Gestion locative",
        "Préparation vente immobilière"
      ]
    }.to_json.html_safe
  end

  def structured_data_service(region)
    region_data = region_seo_data(region)

    {
      "@context": "https://schema.org",
      "@type": "Service",
      "name": region_data[:title],
      "description": region_data[:description],
      "provider": {
        "@type": "Organization",
        "name": "Ren0vate"
      },
      "areaServed": {
        "@type": "State",
        "name": region.capitalize
      },
      "serviceType": "Gestion de chantiers de rénovation",
      "audience": {
        "@type": "Audience",
        "audienceType": "Consumer"
      }
    }.to_json.html_safe
  end
end
