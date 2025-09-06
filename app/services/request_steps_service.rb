class RequestStepsService
  def initialize(request)
    @request = request
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
    case current_step
    when 1 then 0
    when 2 then 15
    when 3 then 30
    when 4 then 50
    when 5 then 70
    when 6 then 85
    when 7 then 100
    end
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

  def basic_info_incomplete?
    @request.title.blank? || @request.description.blank?
  end

  def property_info_incomplete?
    return false unless @request.flandre?

    @request.adresse.blank? ||
    @request.code_postal.blank? ||
    @request.commune.blank? ||
    @request.type_bien.blank?
  end

  def work_details_incomplete?
    return false unless @request.flandre?

    [
      @request.travaux_toiture,
      @request.travaux_murs,
      @request.travaux_sol,
      @request.travaux_vitrage,
      @request.travaux_chauffage
    ].all?(&:nil?)
  end

  def financial_info_incomplete?
    return false unless @request.flandre?

    @request.revenus_annuels.blank? || @request.personnes_charge.blank?
  end

  def documents_incomplete?
    return false unless @request.flandre?

    !@request.document_devis.attached? ||
    !@request.document_factures.attached? ||
    !@request.document_aer.attached?
  end

  def flandre_missing_fields
    fields = []

    # Informations personnelles
    fields << "Nom" if @request.nom.blank?
    fields << "Prénom" if @request.prenom.blank?
    fields << "Email" if @request.email.blank?
    fields << "Téléphone" if @request.telephone.blank?
    fields << "Registre national" if @request.registre_national.blank?

    # Informations du bien
    fields << "Adresse" if @request.adresse.blank?
    fields << "Code postal" if @request.code_postal.blank?
    fields << "Commune" if @request.commune.blank?
    fields << "Type de bien" if @request.type_bien.blank?
    fields << "Usage" if @request.usage.blank?

    # Travaux
    if work_details_incomplete?
      fields << "Sélection des travaux"
    end

    # Finances
    fields << "Revenus annuels" if @request.revenus_annuels.blank?
    fields << "Personnes à charge" if @request.personnes_charge.blank?

    # Documents
    fields << "Devis" unless @request.document_devis.attached?
    fields << "Factures" unless @request.document_factures.attached?
    fields << "AER" unless @request.document_aer.attached?

    fields
  end

  def bruxelles_missing_fields
    fields = []
    fields << "Revenus du ménage" if @request.revenus_menage.blank?
    fields << "Nombre de personnes" if @request.nombre_personnes.blank?
    fields << "Type de travaux" if @request.type_travaux.blank?
    fields
  end

  def wallonie_missing_fields
    fields = []
    fields << "Revenus de référence" if @request.revenus_reference.blank?
    fields << "Composition du ménage" if @request.composition_menage.blank?
    fields << "Catégories de travaux" if @request.categories_travaux.blank?
    fields
  end
end
