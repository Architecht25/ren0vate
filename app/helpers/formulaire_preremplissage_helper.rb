module FormulairePreremplissageHelper
  # Helper pour pré-remplir automatiquement les champs de formulaire
  # Usage: value: preremplir_champ(@form_data, :nom, current_user.last_name)

  def preremplir_champ(form_data, field_name, fallback_value = nil)
    form_data&.dig(field_name) || fallback_value || ""
  end

  # Pré-remplissage conditionnel basé sur le type de champ
  def preremplir_identite(form_data, current_user)
    {
      nom: preremplir_champ(form_data, :nom, current_user.last_name),
      prenom: preremplir_champ(form_data, :prenom, current_user.first_name),
      email: preremplir_champ(form_data, :email, current_user.email),
      telephone: preremplir_champ(form_data, :telephone, current_user.phone),
      registre_national: preremplir_champ(form_data, :registre_national, current_user.national_number),

      # Variations pour les formulaires officiels
      applicant_firstname: preremplir_champ(form_data, :applicant_firstname, current_user.first_name),
      applicant_lastname: preremplir_champ(form_data, :applicant_lastname, current_user.last_name),
      applicant_email: preremplir_champ(form_data, :applicant_email, current_user.email),
      applicant_phone: preremplir_champ(form_data, :applicant_phone, current_user.phone),
      applicant_national_number: preremplir_champ(form_data, :applicant_national_number, current_user.national_number)
    }
  end

  def preremplir_adresse(form_data, property)
    {
      adresse: preremplir_champ(form_data, :adresse, "#{property.numero} #{property.rue}"),
      code_postal: preremplir_champ(form_data, :code_postal, property.code_postal),
      commune: preremplir_champ(form_data, :commune, property.commune),

      # Variations pour formulaires officiels
      heritage_address: preremplir_champ(form_data, :heritage_address, property.rue),
      heritage_number: preremplir_champ(form_data, :heritage_number, property.numero),
      heritage_postal_code: preremplir_champ(form_data, :heritage_postal_code, property.code_postal),
      heritage_city: preremplir_champ(form_data, :heritage_city, property.commune),

      # Adresse du demandeur si différente
      applicant_address: preremplir_champ(form_data, :applicant_address, current_user.street),
      applicant_number: preremplir_champ(form_data, :applicant_number, current_user.number),
      applicant_postal_code: preremplir_champ(form_data, :applicant_postal_code, current_user.postal_code),
      applicant_city: preremplir_champ(form_data, :applicant_city, current_user.city)
    }
  end

  def preremplir_techniques(form_data, property)
    {
      ean: preremplir_champ(form_data, :ean, property.ean_flandre || property.numero_ean),
      parcelle: preremplir_champ(form_data, :parcelle, property.numero_cadastre),
      type_bien: preremplir_champ(form_data, :type_bien, map_property_type(property)),
      usage: preremplir_champ(form_data, :usage, map_property_usage(property)),
      chauffage_post_renovation: preremplir_champ(form_data, :chauffage_post_renovation, property.chauffage_post_renovation_flandre)
    }
  end

  # Badge indiquant si le champ est pré-rempli
  def badge_prerempli(form_data, field_name)
    if form_data&.dig(field_name).present?
      content_tag :span, "✅ Pré-rempli", class: "badge bg-success ms-2"
    else
      content_tag :span, "⚠️ À compléter", class: "badge bg-warning ms-2"
    end
  end

  # Badge intelligent qui vérifie si le champ a une valeur (form_data OU fallback)
  def badge_prerempli_avec_fallback(form_data, field_name, fallback_value)
    valeur_effective = preremplir_champ(form_data, field_name, fallback_value)
    if valeur_effective.present?
      content_tag :span, "✅ Pré-rempli", class: "badge bg-success ms-2"
    else
      content_tag :span, "⚠️ À compléter", class: "badge bg-warning ms-2"
    end
  end

  # Badge intelligent qui vérifie les données de formulaire ET de propriété
  def badge_prerempli_intelligent(form_data, field_name, property_value)
    if form_data&.dig(field_name).present? || property_value.present?
      content_tag :span, "✅ Pré-rempli", class: "badge bg-success ms-2"
    else
      content_tag :span, "⚠️ À compléter", class: "badge bg-warning ms-2"
    end
  end

  # Helper pour détecter si un champ est requis selon les validations du modèle (version simplifiée)
  def field_required?(model_class, field_name, instance = nil)
    return false unless model_class.respond_to?(:validators_on)

    validators = model_class.validators_on(field_name)
    validators.any? do |validator|
      if validator.is_a?(ActiveModel::Validations::PresenceValidator)
        # Pour l'instant, on ignore les conditions complexes et on retourne true pour les champs avec validation presence
        # Cela peut être affiné plus tard
        true
      end
    end
  end

  # Helper pour ajouter des classes CSS aux champs requis
  def form_field_classes(model_class, field_name, base_classes = "form-control", instance = nil)
    classes = base_classes
    if field_required?(model_class, field_name, instance)
      classes += " required-field"
    end
    classes
  end

  # Helper pour créer un label avec indicateur de champ requis
  def required_label(form, field_name, text, model_class = nil, instance = nil, options = {})
    model_class ||= form.object.class if form.respond_to?(:object)

    label_classes = options[:class] || "form-label"

    if model_class && field_required?(model_class, field_name, instance)
      label_classes += " required-label"
      text = "#{text} *".html_safe
    end

    form.label field_name, text, class: label_classes
  end

  # Helper spécifique pour simple_form - ajoute automatiquement les classes requis
  def simple_form_input_html_classes(model_class, field_name, base_classes = {}, instance = nil)
    classes = base_classes[:class] || "form-control-custom"

    if field_required?(model_class, field_name, instance)
      classes += " required-field"
    end

    base_classes.merge(class: classes)
  end

  # Helper pour modifier automatiquement les options de simple_form
  def apply_required_styling(options, model_class, field_name, instance = nil)
    # Copie les options pour ne pas modifier l'original
    styled_options = options.dup

    # Modifie les classes CSS du champ input
    if styled_options[:input_html]
      styled_options[:input_html] = simple_form_input_html_classes(
        model_class,
        field_name,
        styled_options[:input_html],
        instance
      )
    else
      styled_options[:input_html] = simple_form_input_html_classes(
        model_class,
        field_name,
        {},
        instance
      )
    end

    # Ajoute un astérisque au label si requis
    if field_required?(model_class, field_name, instance) && styled_options[:label]
      original_label = styled_options[:label]
      styled_options[:label] = "#{original_label} *" unless original_label.include?("*")
    end

    styled_options
  end

  # Vérifie si une section du formulaire est complètement remplie
  def indicateur_section_complete(form_data, section_fields)
    return nil unless form_data.present?

    complete_count = section_fields.count { |field| form_data[field].present? }
    total_count = section_fields.length

    if complete_count == total_count
      content_tag :span, "✓ Section complète", class: "badge bg-success small ms-2"
    elsif complete_count > 0
      content_tag :span, "#{complete_count}/#{total_count} complété", class: "badge bg-warning small ms-2"
    else
      content_tag :span, "Section vide", class: "badge bg-light text-dark small ms-2"
    end
  end

  # Champs d'identification utilisateur standard
  def champs_identite_utilisateur
    [:applicant_first_name, :applicant_last_name, :applicant_email, :applicant_phone,
     :applicant_national_number, :applicant_street, :applicant_number,
     :applicant_postal_code, :applicant_city]
  end

  # Champs d'adresse de propriété standard
  def champs_adresse_propriete
    [:property_street, :property_number, :property_postal_code, :property_city,
     :property_cadastre_section, :property_cadastre_division, :property_cadastre_parcelle]
  end

  private

  def map_property_type(property)
    case property.region&.downcase
    when 'flandre'
      property.type_bien_flandre
    when 'wallonie'
      property.type_propriete_wallonie
    when 'bruxelles'
      property.type_bien_bruxelles
    else
      property.type
    end
  end

  def map_property_usage(property)
    case property.region&.downcase
    when 'flandre'
      property.usage_flandre
    else
      property.usage || property.occupation
    end
  end
end
