module PropertyCompletionScoring
  extend ActiveSupport::Concern

  # Retourne une analyse détaillée champ par champ de la complétude des données
  def data_completeness_details
    labels = {
      titre: "Nom du bien",
      rue: "Rue", numero: "Numéro", code_postal: "Code postal",
      commune: "Commune", region: "Région",
      type_propriete_wallonie: "Type de propriété (Wallonie)",
      type_bien_wallonie: "Type de bien (Wallonie)",
      profil_demandeur: "Profil demandeur",
      certificat_peb_wallonie: "Certificat PEB (Wallonie)",
      occupation: "Type d'occupation",
      surface_habitable_wallonie: "Surface habitable (m²)",
      mode_chauffage_wallonie: "Mode de chauffage",
      annee_construction: "Année de construction",
      type_bien_flandre: "Type de bien (Flandre)",
      usage_flandre: "Usage (Flandre)",
      certificat_peb_flandre: "Certificat PEB (Flandre)",
      surface_habitable: "Surface habitable (m²)",
      chauffage_post_renovation_flandre: "Chauffage post-rénovation",
      ean_flandre: "Numéro EAN (Flandre)",
      type_bien_bruxelles: "Type de bien (Bruxelles)",
      certificat_peb_bruxelles: "Certificat PEB (Bruxelles)",
      surface_totale: "Surface totale (m²)",
      numero_cadastre: "Numéro cadastral",
      valeur_achat: "Valeur d'achat",
      date_achat: "Date d'achat"
    }

    identite = {
      label: "Identité du bien",
      fields: build_field_details([:titre, :rue, :numero, :code_postal, :commune, :region, :numero_cadastre], labels)
    }

    admin = {
      label: "Informations administratives",
      fields: build_field_details(admin_fields_for_region - [:rue, :numero, :code_postal, :commune, :region], labels)
    }

    technique = {
      label: "Caractéristiques techniques",
      fields: build_field_details(chantier_fields_for_region, labels)
    }

    investissement = {
      label: "Valeur & investissement",
      fields: build_field_details([:valeur_achat, :date_achat], labels)
    }

    categories = [identite, admin, technique, investissement].map do |cat|
      total = cat[:fields].count
      done = cat[:fields].count { |f| f[:filled] }
      cat.merge(total: total, done: done, percentage: total.zero? ? 0 : (done.to_f / total * 100).round)
    end

    all_fields = categories.flat_map { |c| c[:fields] }
    global_total = all_fields.count
    global_done = all_fields.count { |f| f[:filled] }

    {
      categories: categories,
      total: global_total,
      done: global_done,
      percentage: global_total.zero? ? 0 : (global_done.to_f / global_total * 100).round,
      missing: all_fields.reject { |f| f[:filled] }.map { |f| f[:label] }
    }
  end

  def completion_percentage
    admin_weight = 0.3
    chantier_weight = 0.3
    primes_weight = 0.2
    documents_weight = 0.2

    overall = (admin_completion_percentage * admin_weight +
               chantier_completion_percentage * chantier_weight +
               primes_completion_percentage * primes_weight +
               documents_completion_percentage * documents_weight)

    overall.round
  end

  def admin_completion_percentage
    admin_fields = admin_fields_for_region
    total = admin_fields.count
    completed = admin_fields.count { |field| self[field].present? }
    return 0 if total.zero?
    (completed.to_f / total * 100).round
  end

  def chantier_completion_percentage
    chantier_fields = chantier_fields_for_region
    total = chantier_fields.count
    completed = chantier_fields.count { |field| self[field].present? }
    return 0 if total.zero?
    (completed.to_f / total * 100).round
  end

  def primes_completion_percentage
    # Pour l'instant, on se base sur la présence d'au moins une simulation
    simulations.any? ? 100 : 0
  end

  def ready_for_request?
    completion_percentage >= 80
  end

  def completion_status
    percentage = completion_percentage
    case percentage
    when 0...30 then 'danger'
    when 30...70 then 'warning'
    when 70...90 then 'info'
    else 'success'
    end
  end

  def admin_completion_class
    case admin_completion_percentage
    when 0...50 then 'bg-danger'
    when 50...80 then 'bg-warning'
    else 'bg-success'
    end
  end

  def chantier_completion_class
    case chantier_completion_percentage
    when 0...50 then 'bg-danger'
    when 50...80 then 'bg-warning'
    else 'bg-success'
    end
  end

  def primes_completion_class
    primes_completion_percentage > 0 ? 'bg-success' : 'bg-secondary'
  end

  # Méthode de debug pour voir quels champs sont évalués
  def completion_debug_info
    {
      region: region,
      admin_fields: admin_fields_for_region,
      admin_completed: admin_fields_for_region.select { |field| self[field].present? },
      admin_missing: admin_fields_for_region.select { |field| self[field].blank? },
      chantier_fields: chantier_fields_for_region,
      chantier_completed: chantier_fields_for_region.select { |field| self[field].present? },
      chantier_missing: chantier_fields_for_region.select { |field| self[field].blank? }
    }
  end

  def documents_completion_percentage
    stats = Document.completion_stats_for_property(self)
    stats[:percentage]
  end

  def documents_completion_class
    case documents_completion_percentage
    when 0...50 then 'bg-danger'
    when 50...80 then 'bg-warning'
    else 'bg-success'
    end
  end

  def completed_documents_count
    stats = Document.completion_stats_for_property(self)
    stats[:completed]
  end

  def total_required_documents
    stats = Document.completion_stats_for_property(self)
    stats[:total]
  end

  def documents_by_type
    documents.group_by(&:type_document)
  end

  # Méthodes pour le formulaire miroir
  def ready_for_submission?
    admin_completion_percentage >= 80 &&
    chantier_completion_percentage >= 60 &&
    documents_completion_percentage >= 80
  end

  def missing_for_submission
    missing = []
    missing << "Informations administratives incomplètes" if admin_completion_percentage < 80
    missing << "Informations chantier incomplètes" if chantier_completion_percentage < 60
    missing << "Documents manquants" if documents_completion_percentage < 80
    missing
  end

  def has_travaux?(type)
    # À adapter selon votre logique de travaux
    # Pour l'instant, retourne false - à implémenter avec vos données
    false
  end

  def submission_readiness_class
    if ready_for_submission?
      'bg-success'
    elsif completion_percentage >= 50
      'bg-warning'
    else
      'bg-danger'
    end
  end

  def missing_required_fields
    required_fields.select { |field| self[field].blank? }
  end

  def admin_fields_for_region
    # Champs de base communs à toutes les régions
    fields = [:rue, :numero, :code_postal, :commune, :region]

    # Ajout des champs régionaux selon la région
    case region&.downcase
    when 'wallonie'
      fields += [:type_propriete_wallonie, :type_bien_wallonie, :profil_demandeur, :certificat_peb_wallonie]
    when 'flandre'
      fields += [:type_bien_flandre, :usage_flandre, :certificat_peb_flandre]
    when 'bruxelles'
      fields += [:type_bien_bruxelles, :certificat_peb_bruxelles, :profil_demandeur]
    else
      # Fallback vers l'ancien champ générique si pas de région définie
      fields += [:type] if respond_to?(:type)
    end

    fields
  end

  def chantier_fields_for_region
    # Champs de base communs à toutes les régions
    fields = [:annee_construction]

    # Ajout des champs régionaux spécifiques selon la région
    case region&.downcase
    when 'wallonie'
      # Pour la Wallonie : surface habitable, mode de chauffage et occupation
      fields += [:surface_habitable_wallonie, :mode_chauffage_wallonie, :occupation]
    when 'flandre'
      # Pour la Flandre : surface habitable, système chauffage et EAN
      fields += [:surface_habitable, :chauffage_post_renovation_flandre, :ean_flandre]
    when 'bruxelles'
      # Pour Bruxelles : surface habitable et champs spécifiques
      fields += [:surface_habitable, :usage, :occupation, :surface_totale]
    else
      # Fallback vers les anciens champs génériques si pas de région définie
      fields += [:surface_habitable, :date_raccordement_electrique, :numero_ean, :autre_bien, :peb]
    end

    fields
  end

  private

  def required_fields
    # Champs minimum requis pour l'enregistrement
    fields = [:rue, :numero, :code_postal, :commune, :region]

    # Ajout des champs régionaux requis selon la région
    # Exclure type_bien_bruxelles pour les entreprises car incompatible avec éligibilité Renolution
    case region&.downcase
    when 'wallonie'
      fields += [:type_propriete_wallonie]
    when 'flandre'
      fields += [:type_bien_flandre]
    when 'bruxelles'
      # Pour les entreprises, ne pas exiger type_bien_bruxelles
      fields += [:type_bien_bruxelles] unless is_entreprise?
    when 'espagne'
      fields += [:type]
    end

    fields
  end

  def build_field_details(fields, labels)
    fields.uniq.map do |field|
      value = self[field]
      { field: field, label: labels[field] || field.to_s.humanize, filled: value.present?, value: value }
    end
  end
end
