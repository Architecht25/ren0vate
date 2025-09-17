module ApplicationHelper
  include FormulairePreremplissageHelper

  # Helper pour les URLs d'images Active Storage sans paramètre locale
  def image_url_without_locale(attachment)
    return nil unless attachment.attached?

    # Générer l'URL sans paramètres de locale
    Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: false, host: request.host_with_port)
  end

  # Helper pour les images de propriétés avec fallback
  def property_image_tag(property, options = {})
    if property.photo.attached?
      image_tag image_url_without_locale(property.photo), options
    else
      # Icône par défaut si pas de photo
      icon_class = property.is_entreprise? ? 'building' : 'house-door'
      content_tag :div, class: "h-100 w-100 d-flex align-items-center justify-content-center bg-light #{options[:class]}" do
        content_tag :i, '', class: "bi bi-#{icon_class} text-muted fs-4"
      end
    end
  end

  # Détermine si l'utilisateur actuel est un administrateur
  def current_user_admin?
    return false unless user_signed_in?
    # Pour l'instant, basé sur l'email admin - à améliorer avec un vrai système de rôles
    current_user.email == 'robin@primes-services.be'
  end

  # Helper pour les statuts RequestProgress
  def request_progress_status_badge(status)
    status_config = {
      'en_preparation' => { class: 'secondary', icon: 'clock', text: 'En préparation' },
      'soumis' => { class: 'primary', icon: 'upload', text: 'Soumis' },
      'en_cours' => { class: 'info', icon: 'arrow-repeat', text: 'En cours' },
      'complet' => { class: 'success', icon: 'check-circle', text: 'Complet' },
      'incomplet' => { class: 'warning', icon: 'exclamation-triangle', text: 'Incomplet' },
      'accorde' => { class: 'success', icon: 'check-circle-fill', text: 'Accordé' },
      'refuse' => { class: 'danger', icon: 'x-circle', text: 'Refusé' },
      'annule' => { class: 'dark', icon: 'slash-circle', text: 'Annulé' }
    }

    config = status_config[status] || status_config['en_preparation']

    content_tag :span, class: "badge bg-#{config[:class]}" do
      concat content_tag(:i, '', class: "bi bi-#{config[:icon]} me-1")
      concat config[:text]
    end
  end

  # Helper pour formater les montants
  def format_currency_amount(amount)
    return content_tag(:small, '-', class: 'text-muted') if amount.blank? || amount.zero?

    number_to_currency(amount, unit: '€', separator: ',', delimiter: ' ')
  end

  # Helper pour le taux d'octroi avec couleur
  def format_taux_octroi(taux)
    return '' if taux.zero?

    color_class = case taux
                 when 0..25 then 'text-danger'
                 when 26..50 then 'text-warning'
                 when 51..75 then 'text-info'
                 else 'text-success'
                 end

    content_tag :small, "(#{taux}%)", class: "#{color_class} fw-semibold"
  end

  # Helper pour obtenir les options de types de formulaires selon la région
  def options_for_select_form_types(region = nil)
    # Normaliser la région pour être case-insensitive
    normalized_region = region&.downcase

    case normalized_region
    when 'wallonie'
      [
        ['audit', 'Prime Audit Énergétique'],
        ['regionale', 'Prime Régionale'],
        ['communale', 'Primes Communales'],
        ['monument', 'Prime Monument & Site']
      ]
    when 'flandre'
      [
        ['regional', 'Formulaire régional'],
        ['communal', 'Formulaires communaux'],
        ['monuments', 'Monuments & Sites']
      ]
    when 'bruxelles'
      [
        ['regional', 'Formulaire régional'],
        ['monuments', 'Monuments & Sites'],
        ['petit_patrimoine', 'Petit patrimoine'],
        ['communal', 'Primes communales']
      ]
    else
      [
        ['regional', 'Formulaire régional'],
        ['communal', 'Formulaires communaux'],
        ['monuments', 'Monuments & Sites']
      ]
    end
  end

  # Génère l'URL d'image Cloudinary pour une prime spécifique
  def prime_specific_image_url(prime, transformations = {})
    return nil unless prime

    # Mapping des types de primes vers leurs IDs Cloudinary spécifiques
    cloudinary_image_mapping = {
      # Isolation toiture - mots-clés spécifiques
      'isolation thermique de la toiture' => 'isolation_toiture_f9r4hs',
      'isolation de la toiture' => 'isolation_toiture_f9r4hs',
      'isolation thermique du toit' => 'isolation_toiture_f9r4hs',
      'isolation.*toiture' => 'isolation_toiture_f9r4hs',
      'toiture.*isolation' => 'isolation_toiture_f9r4hs',

      # Isolation murs
      'isolation.*murs' => 'isolation_murs_ext_ahbpat',
      'murs.*isolation' => 'isolation_murs_ext_ahbpat',
      'isolation.*façade' => 'isolation_murs_ext_ahbpat',
      'façade.*isolation' => 'isolation_murs_ext_ahbpat',

      # Isolation sols
      'isolation.*sol' => 'isolation_sol_kokpgs',
      'sol.*isolation' => 'isolation_sol_kokpgs',
      'isolation.*plancher' => 'isolation_sol_kokpgs',
      'plancher.*isolation' => 'isolation_sol_kokpgs',

      # Chauffage et énergie
      'pompe.*chaleur' => 'pac_géothermique_cj7l2y',
      'pac' => 'pac_géothermique_cj7l2y',
      'chauffe.*eau' => 'pac_géothermique_cj7l2y',
      'chauffage' => 'pac_géothermique_cj7l2y',
      'hybride' => 'pac_hybride_ukmzp8',
      'solaire' => 'aurostep-plus-avec-capteurs-solaire-389237-format-flex-height_yzlwxc',

      # Ouvertures
      'châssis' => 'remplacement_chassis_lrszxo',
      'chassis' => 'remplacement_chassis_lrszxo',
      'fenêtre' => 'remplacement_chassis_lrszxo',
      'fenetre' => 'remplacement_chassis_lrszxo',
      'porte' => 'remplacement_chassis_lrszxo',

      # Ventilation
      'ventilation' => 'Housing-Ventilation-Shutterstock-16-9-1920x1080px_uxckrq',

      # Rénovation
      'rénovation.*toiture' => 'renovation_toiture_guwknw',
      'renovation.*toiture' => 'renovation_toiture_guwknw',
      'structure.*toiture' => 'renovation_toiture_guwknw',
      'couverture' => 'renovation_toiture_guwknw',

      # Efficacité énergétique
      'efficacité' => 'efficacite-energetique-batiment_mlgdaj',
      'efficacite' => 'efficacite-energetique-batiment_mlgdaj',
      'audit' => 'efficacite-energetique-batiment_mlgdaj'
    }

    # Déterminer l'ID Cloudinary basé sur le titre ou slug de la prime
    cloudinary_id = determine_cloudinary_id_for_prime(prime, cloudinary_image_mapping)

    # Debug en développement
    Rails.logger.debug "Prime: #{prime.titre} -> Cloudinary ID: #{cloudinary_id}" if Rails.env.development?

    default_transformations = {
      width: 48,
      height: 48
    }

    build_cloudinary_url(cloudinary_id, default_transformations.merge(transformations))
  end

  private

  def determine_cloudinary_id_for_prime(prime, mapping)
    title_lower = prime.titre.downcase
    slug_lower = prime.slug.downcase if prime.respond_to?(:slug)

    # Debug: afficher le titre pour comprendre le mapping
    Rails.logger.debug "Prime titre: #{prime.titre}" if Rails.env.development?

    # Rechercher par mots-clés dans le titre et slug
    mapping.each do |pattern, cloudinary_id|
      # Utiliser regex si le pattern contient des caractères regex
      if pattern.include?('.*')
        regex = Regexp.new(pattern, Regexp::IGNORECASE)
        if title_lower.match?(regex) || (slug_lower && slug_lower.match?(regex))
          Rails.logger.debug "Matched pattern: #{pattern} -> #{cloudinary_id}" if Rails.env.development?
          return cloudinary_id
        end
      else
        # Recherche simple par inclusion
        if title_lower.include?(pattern) || (slug_lower && slug_lower.include?(pattern))
          Rails.logger.debug "Matched keyword: #{pattern} -> #{cloudinary_id}" if Rails.env.development?
          return cloudinary_id
        end
      end
    end

    # Image par défaut si aucune correspondance
    Rails.logger.debug "No match found, using default image" if Rails.env.development?
    'efficacite-energetique-batiment_mlgdaj'
  end

  def build_cloudinary_url(cloudinary_id, transformations = {})
    # Utiliser la même approche que dans les cartes de simulation
    cloud_name = ENV['CLOUDINARY_CLOUD_NAME'] || 'dyfkqjv3r'  # fallback

    # Format des transformations pour correspondre à l'exemple
    transform_params = []
    transform_params << "c_fill"
    transform_params << "w_#{transformations[:width] || 48}"
    transform_params << "h_#{transformations[:height] || 48}"
    transform_params << "q_auto"
    transform_params << "f_auto"

    transform_string = transform_params.join(',')

    "https://res.cloudinary.com/#{cloud_name}/image/upload/#{transform_string}/#{cloudinary_id}"
  end
end
