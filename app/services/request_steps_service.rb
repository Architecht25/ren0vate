class RequestStepsService
  def initialize(request)
    @request = request
    @user = request.user
    @property = request.property
  end

  def current_step
    return 1 if @request.region.blank?
    return 2 if basic_info_incomplete?
    return 3 if property_info_incomplete?
    return 4 if work_details_incomplete?
    return 5 if financial_info_incomplete?
    return 6 if documents_incomplete?
    return 7 # Prêt à soumettre
  end

  def step_name
    case current_step
    when 1 then "Sélection de la région"
    when 2 then "Informations de base"
    when 3 then "Informations du bien"
    when 4 then "Détails des travaux"
    when 5 then "Informations financières"
    when 6 then "Documents"
    when 7 then "Prêt à soumettre"
    end
  end

  def step_completion_percentage
    # Calcul plus granulaire basé sur les champs réellement manquants
    total_sections = 6.0
    completion = 0.0

    # Section 1: Région (toujours complète si on arrive ici)
    completion += 1.0

    # Section 2: Informations de base
    completion += 1.0 unless basic_info_incomplete?

    # Section 3: Informations du bien (avec granularité)
    if @request.flandre?
      property_fields_total = 6.0 # adresse, cp, commune, type, usage, ean
      property_fields_complete = 0.0
      property_fields_complete += 1 unless get_field_value(:adresse, @property&.rue.present? && @property&.numero.present? ? "#{@property.rue} #{@property.numero}" : nil).blank?
      property_fields_complete += 1 unless get_field_value(:code_postal, @property&.code_postal).blank?
      property_fields_complete += 1 unless get_field_value(:commune, @property&.commune).blank?
      property_fields_complete += 1 unless get_field_value(:type_bien, @property&.type_bien_flandre).blank?
      property_fields_complete += 1 unless get_field_value(:usage, @property&.usage_flandre).blank?
      property_fields_complete += 1 unless get_field_value(:code_ean, @property&.ean_flandre).blank?
      completion += property_fields_complete / property_fields_total
    else
      completion += 1.0 unless property_info_incomplete?
    end

    # Section 4: Détails des travaux
    completion += 1.0 unless work_details_incomplete?

    # Section 5: Informations financières
    completion += 1.0 unless financial_info_incomplete?

    # Section 6: Documents
    completion += 1.0 unless documents_incomplete?

    (completion / total_sections * 100).round
  end

  def can_advance_to_step?(step_number)
    current_step >= step_number
  end

  def missing_fields_for_completion
    fields = []

    case @request.region
    when 'flandre'
      fields = flandre_missing_fields
    when 'bruxelles'
      fields = bruxelles_missing_fields
    when 'wallonie'
      fields = wallonie_missing_fields
    end

    fields
  end

  private

  # Helper pour récupérer une valeur avec fallback (comme dans le formulaire)
  def get_field_value(field_name, fallback_value = nil)
    @request.form_data&.dig(field_name) || fallback_value || ""
  end

  def basic_info_incomplete?
    get_field_value(:nom, @user&.last_name).blank? ||
    get_field_value(:prenom, @user&.first_name).blank? ||
    get_field_value(:email, @user&.email).blank? ||
    get_field_value(:telephone, @user&.phone).blank? ||
    get_field_value(:registre_national, @user&.national_number).blank?
  end

  def property_info_incomplete?
    return false unless @request.flandre?

    get_field_value(:adresse, @property&.rue.present? && @property&.numero.present? ? "#{@property.rue} #{@property.numero}" : nil).blank? ||
    get_field_value(:code_postal, @property&.code_postal).blank? ||
    get_field_value(:commune, @property&.commune).blank? ||
    get_field_value(:type_bien, @property&.type_bien_flandre).blank? ||
    get_field_value(:usage, @property&.usage_flandre).blank? ||
    get_field_value(:code_ean, @property&.ean_flandre).blank?
  end

  def work_details_incomplete?
    return false unless @request.flandre?

    # Vérifier s'il y a au moins un travaux sélectionné
    travaux_fields = [:travaux_toiture, :travaux_murs, :travaux_sol, :travaux_vitrage, :travaux_chauffage, :travaux_ventilation, :travaux_complementaires]

    travaux_fields.none? do |field|
      value = get_field_value(field)
      value == "true" || value == true || value == "1"
    end
  end

  def financial_info_incomplete?
    return false unless @request.flandre?

    get_field_value(:revenus_annuels, @user&.household_income).blank? ||
    get_field_value(:personnes_charge, @user&.nombre_enfants).blank? ||
    get_field_value(:annee_aer, @user&.annee_revenus_demandeur).blank?
  end

  def documents_incomplete?
    return false unless @request.flandre?

    !@request.document_devis.attached? ||
    !@request.document_factures.attached? ||
    !@request.document_aer.attached?
  end

  def flandre_missing_fields
    fields = []

    # Informations de base (généralement pré-remplies)
    fields << "Nom" if get_field_value(:nom, @user&.last_name).blank?
    fields << "Prénom" if get_field_value(:prenom, @user&.first_name).blank?
    fields << "Email" if get_field_value(:email, @user&.email).blank?
    fields << "Téléphone" if get_field_value(:telephone, @user&.phone).blank?
    fields << "Registre national" if get_field_value(:registre_national, @user&.national_number).blank?

    # Informations du bien (généralement pré-remplies sauf code EAN)
    fields << "Adresse" if get_field_value(:adresse, @property&.rue.present? && @property&.numero.present? ? "#{@property.rue} #{@property.numero}" : nil).blank?
    fields << "Code postal" if get_field_value(:code_postal, @property&.code_postal).blank?
    fields << "Commune" if get_field_value(:commune, @property&.commune).blank?
    fields << "Type de bien" if get_field_value(:type_bien, @property&.type_bien_flandre).blank?
    fields << "Usage" if get_field_value(:usage, @property&.usage_flandre).blank?
    fields << "Code EAN" if get_field_value(:code_ean, @property&.ean_flandre).blank?

    # Travaux (souvent à sélectionner manuellement)
    travaux_fields = [:travaux_toiture, :travaux_murs, :travaux_sol, :travaux_vitrage, :travaux_chauffage, :travaux_ventilation, :travaux_complementaires]
    if travaux_fields.none? { |field| ["true", true, "1"].include?(get_field_value(field)) }
      fields << "Sélection des travaux"
    end

    # Informations financières (généralement pré-remplies)
    fields << "Revenus annuels" if get_field_value(:revenus_annuels, @user&.household_income).blank?
    fields << "Personnes à charge" if get_field_value(:personnes_charge, @user&.nombre_enfants).blank?
    fields << "Année AER" if get_field_value(:annee_aer, @user&.annee_revenus_demandeur).blank?

    # Documents (requis)
    fields << "Document devis" unless @request.document_devis.attached?
    fields << "Document factures" unless @request.document_factures.attached?
    fields << "Document AER" unless @request.document_aer.attached?

    fields
  end

  def bruxelles_missing_fields
    fields = []

    # Informations de base
    fields << "Nom" if get_field_value(:nom, @user&.last_name).blank?
    fields << "Prénom" if get_field_value(:prenom, @user&.first_name).blank?
    fields << "Email" if get_field_value(:email, @user&.email).blank?
    fields << "Téléphone" if get_field_value(:telephone, @user&.phone).blank?

    # Informations du bien
    fields << "Adresse" if get_field_value(:adresse, @property&.adresse).blank?
    fields << "Code postal" if get_field_value(:code_postal, @property&.code_postal).blank?
    fields << "Commune" if get_field_value(:commune, @property&.commune).blank?

    fields
  end

  def wallonie_missing_fields
    fields = []

    # Informations de base
    fields << "Nom" if get_field_value(:nom, @user&.last_name).blank?
    fields << "Prénom" if get_field_value(:prenom, @user&.first_name).blank?
    fields << "Email" if get_field_value(:email, @user&.email).blank?
    fields << "Téléphone" if get_field_value(:telephone, @user&.phone).blank?

    # Informations du bien
    fields << "Adresse" if get_field_value(:adresse, @property&.adresse).blank?
    fields << "Code postal" if get_field_value(:code_postal, @property&.code_postal).blank?
    fields << "Commune" if get_field_value(:commune, @property&.commune).blank?

    fields
  end

end
