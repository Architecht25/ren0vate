# Service pour déterminer les documents obligatoires selon les primes sélectionnées
class DecisionHub::DocumentRequirementsService
  def self.for_simulation(simulation)
    new(simulation).generate_requirements
  end

  def initialize(simulation)
    @simulation = simulation
    @region = simulation.region&.downcase || "wallonie"
    @selected_primes = extract_selected_primes(simulation)
  end

  def generate_requirements
    {
      required_documents: get_required_documents,
      key_documents: get_key_documents,
      completion_rate: calculate_completion_rate,
      completed: get_completed_documents,
      missing: get_missing_documents,
      urgent: get_urgent_documents,
      by_category: group_by_category
    }
  end

  private

  def get_required_documents
    base_documents = [
      {
        id: "devis_rge",
        name: "Devis entrepreneur agréé",
        category: "administrative",
        status: "missing",
        urgency: "critical",
        required_for: all_primes_names,
        deadline: "Avant dépôt",
        details: "Devis détaillé avec matériaux, main d'œuvre et délais"
      },
      {
        id: "photos_avant",
        name: "Photos avant travaux horodatées",
        category: "administrative",
        status: "missing",
        urgency: "high",
        required_for: all_primes_names,
        deadline: "Avant commencement",
        details: "Photos datées de l'état initial des zones à rénover"
      }
    ]

    # Documents spécifiques par région
    region_documents = case @region
    when "bruxelles"
      if @simulation&.property&.bien_classe?
        [
          {
            id: "permis_unique_ou_plan_gestion",
            name: "Permis unique ou plan de gestion patrimoniale",
            category: "administrative",
            status: "missing",
            urgency: "critical",
            required_for: all_primes_names,
            deadline: "Avant tout début de travaux ou d'études",
            details: "Autorisation urbanistique obligatoire (sauf actes de minime importance)"
          },
          {
            id: "droit_sur_le_bien",
            name: "Attestation de propriété ou autre droit réel",
            category: "administrative",
            status: "missing",
            urgency: "high",
            required_for: all_primes_names,
            deadline: "Avant dépôt",
            details: "Usufruit, emphytéose, bail + autorisation du propriétaire, ou décision de copropriété"
          }
        ]
      elsif @simulation&.property&.petit_patrimoine?
        [
          {
            id: "photo_elements_patrimoine",
            name: "Photo de chaque élément de petit patrimoine concerné",
            category: "administrative",
            status: "missing",
            urgency: "critical",
            required_for: all_primes_names,
            deadline: "Avant dépôt",
            details: "Photo couleur récente de la façade, du jardinet et de chaque élément"
          },
          {
            id: "permis_ou_accuse_reception",
            name: "Copie du permis ou de l'accusé de réception (si requis)",
            category: "administrative",
            status: "missing",
            urgency: "high",
            required_for: all_primes_names,
            deadline: "Avant dépôt",
            details: "Selon la nature des travaux et le statut du bien (CADRE VII)"
          }
        ]
      else
        [
          {
            id: "audit_pae",
            name: "Audit PAE par conseiller agréé",
            category: "administrative",
            status: "missing",
            urgency: "critical",
            required_for: primes_with_category("audit"),
            deadline: "Avant travaux",
            details: "Audit énergétique PAE obligatoire pour primes de rénovation Bruxelles"
          },
          {
            id: "declaration_urbanisme",
            name: "Déclaration préalable urbanisme",
            category: "administrative",
            status: "missing",
            urgency: "high",
            required_for: primes_with_category("isolation"),
            deadline: "20 jours ouvrables",
            details: "Déclaration si modification aspect extérieur"
          }
        ]
      end
    else
      [
        {
          id: "certificat_peb",
          name: "Certificat PEB valide (< 10 ans)",
          category: "administrative",
          status: "completed",
          urgency: "critical",
          required_for: all_primes_names,
          deadline: "Requis maintenant",
          details: "Performance énergétique du bâtiment"
        },
        {
          id: "declaration_commune",
          name: "Déclaration préalable commune",
          category: "administrative",
          status: "missing",
          urgency: "medium",
          required_for: primes_with_category("isolation"),
          deadline: "15 jours ouvrables",
          details: "Déclaration selon règlement communal"
        }
      ]
    end

    # Documents techniques spécifiques par type de prime
    technical_documents = []

    if has_isolation_prime?
      technical_documents += [
        {
          id: "fiche_technique_isolant",
          name: "Fiches techniques matériaux isolants",
          category: "technical",
          status: "missing",
          urgency: "high",
          required_for: primes_with_category("isolation"),
          deadline: "Avec devis",
          details: "Marquage CE, résistance thermique, lambda"
        }
      ]
    end

    if has_heating_prime?
      technical_documents += [
        {
          id: "fiche_technique_pac",
          name: "Fiche technique pompe à chaleur",
          category: "technical",
          status: "missing",
          urgency: "high",
          required_for: primes_with_category("chauffage"),
          deadline: "Avec devis",
          details: "COP, puissance, certification EHPA"
        }
      ]
    end

    (base_documents + region_documents + technical_documents).uniq { |doc| doc[:id] }
  end

  def get_completed_documents
    if dynamic_tracking_region?
      key_docs = get_key_documents
      return key_docs.select { |doc| doc[:status] == "completed" }.map { |doc| doc[:name] }
    end

    get_required_documents.select { |doc| doc[:status] == "completed" }.map { |doc| doc[:name] }
  end

  def get_missing_documents
    if dynamic_tracking_region?
      key_docs = get_key_documents
      return key_docs.select { |doc| doc[:status] == "missing" }.map { |doc| doc[:name] }
    end

    get_required_documents.select { |doc| doc[:status] == "missing" }.map { |doc| doc[:name] }
  end

  def calculate_completion_rate
    if dynamic_tracking_region?
      key_docs = get_key_documents
      completed_count = key_docs.count { |doc| doc[:status] == "completed" }
      total_count = @region == "flandre" ? 8 : key_docs.count # Total documents Flandre (3 obligatoires + 5 complémentaires)
      return 0 if total_count == 0

      return ((completed_count.to_f / total_count) * 100).round
    end

    documents = get_required_documents
    completed_count = documents.count { |doc| doc[:status] == "completed" }
    total_count = documents.count
    return 0 if total_count == 0

    ((completed_count.to_f / total_count) * 100).round
  end

  def get_urgent_documents
    if dynamic_tracking_region?
      key_docs = get_key_documents
      return key_docs.select { |doc| doc[:urgent] }.map { |doc| doc[:name] }
    end

    get_required_documents.select { |doc| doc[:urgency] == "high" || doc[:urgency] == "critical" }.map { |doc| doc[:name] }
  end

  def group_by_category
    docs = get_required_documents
    {
      administrative: docs.select { |doc| doc[:category] == "administrative" },
      technical: docs.select { |doc| doc[:category] == "technical" }
    }
  end

  # Helpers
  def extract_selected_primes(simulation)
    # Réutilise la logique du DataService
    DecisionHub::DataService.new(simulation).send(:extract_selected_primes)
  end

  def all_primes_names
    @selected_primes.map { |prime| prime[:name] }
  end

  def primes_with_category(category)
    @selected_primes.select { |prime| prime[:category] == category }.map { |prime| prime[:name] }
  end

  def has_isolation_prime?
    @selected_primes.any? { |prime| prime[:category] == "isolation" }
  end

  def has_heating_prime?
    @selected_primes.any? { |prime| prime[:category] == "chauffage" }
  end

  def dynamic_tracking_region?
    ["flandre", "bruxelles"].include?(@region)
  end

  def get_key_documents
    if @region == "bruxelles"
      property = @simulation&.property
      documents = property&.documents || []
      active_statuses = ["approved", "pending"]

      has_devis = documents.any? { |d| d.type_document == "devis" && active_statuses.include?(d.status) }
      has_photos = documents.any? { |d| ["photo", "photo_avant"].include?(d.type_document) && active_statuses.include?(d.status) }

      base_key_docs = [
        {
          name: "Devis entrepreneur agréé",
          category: "administrative",
          status: has_devis ? "completed" : "missing",
          description: "Devis détaillé avec matériaux, main d'œuvre et délais",
          deadline: "Avant dépôt",
          urgent: !has_devis
        },
        {
          name: "Photos avant travaux",
          category: "administrative",
          status: has_photos ? "completed" : "missing",
          description: "Photos datées de l'état initial des zones à rénover",
          deadline: "Avant commencement",
          urgent: !has_photos
        }
      ]

      if property&.bien_classe?
        has_permis = documents.any? { |d| d.type_document == "permis_urbanisme" && active_statuses.include?(d.status) }
        return base_key_docs + [
          {
            name: "Permis unique ou plan de gestion patrimoniale",
            category: "administrative",
            status: has_permis ? "completed" : "missing",
            description: "Autorisation urbanistique obligatoire avant travaux",
            deadline: "Avant tout début de travaux ou d'études",
            urgent: !has_permis
          }
        ]
      elsif property&.petit_patrimoine?
        has_permis = documents.any? { |d| d.type_document == "permis_urbanisme" && active_statuses.include?(d.status) }
        return base_key_docs + [
          {
            name: "Copie du permis ou accusé de réception",
            category: "administrative",
            status: has_permis ? "completed" : "missing",
            description: "Selon la nature des travaux et le statut du bien (CADRE VII)",
            deadline: "Avant dépôt",
            urgent: !has_permis
          }
        ]
      end

      has_audit = documents.any? { |d| ["rapport_audit_energetique", "preuve_paiement_audit"].include?(d.type_document) && active_statuses.include?(d.status) }
      has_urbanisme = documents.any? { |d| d.type_document == "permis_urbanisme" && active_statuses.include?(d.status) }

      return base_key_docs + [
        {
          name: "Audit PAE",
          category: "administrative",
          status: has_audit ? "completed" : "missing",
          description: "Audit énergétique PAE par conseiller agréé",
          deadline: "Avant travaux",
          urgent: !has_audit
        },
        {
          name: "Déclaration préalable urbanisme",
          category: "administrative",
          status: has_urbanisme ? "completed" : "missing",
          description: "Déclaration si modification de l'aspect extérieur",
          deadline: "20 jours ouvrables",
          urgent: !has_urbanisme
        }
      ]
    end

    if @region == "flandre"
      # Pour la région Flandre, utiliser les documents obligatoires avec statut dynamique
      property = @simulation&.property
      documents = property&.documents || []

      # Vérifier la présence de documents par type (inclut pending et approved)
      has_devis = documents.any? { |d| d.type_document == 'devis' && ['approved', 'pending'].include?(d.status) }
      has_factures = documents.any? { |d| d.type_document == 'facture' && ['approved', 'pending'].include?(d.status) }
      has_attestations = documents.any? { |d| d.type_document == 'attestation_entrepreneur' && ['approved', 'pending'].include?(d.status) }

      return [
        {
          name: "Devis des tr...",
          category: "administrative",
          status: has_devis ? "completed" : "missing",
          description: "Devis détaillé des travaux à réaliser",
          deadline: "Avant dépôt",
          urgent: !has_devis
        },
        {
          name: "Factures des...",
          category: "administrative",
          status: has_factures ? "completed" : "missing",
          description: "Factures finales des travaux réalisés",
          deadline: "Après travaux",
          urgent: !has_factures
        },
        {
          name: "Attestations...",
          category: "technical",
          status: has_attestations ? "completed" : "missing",
          description: "Attestations techniques des entrepreneurs",
          deadline: "Avec dépôt",
          urgent: !has_attestations
        }
      ]
    end

    # Logique existante pour les autres régions
    all_docs = get_required_documents

    # Sélectionner les 5 documents les plus importants/urgents
    key_docs = all_docs.select { |doc| doc[:importance] == "critical" || doc[:urgency] == "high" }
                      .first(5)

    # Si on n'a pas assez de documents critiques, compléter avec d'autres
    if key_docs.count < 5
      remaining = all_docs.reject { |doc| key_docs.include?(doc) }
                         .first(5 - key_docs.count)
      key_docs += remaining
    end

    # Formater pour l'affichage compact
    key_docs.map do |doc|
      {
        name: doc[:name],
        category: doc[:category],
        status: determine_document_status(doc),
        description: doc[:description],
        deadline: doc[:deadline],
        urgent: doc[:urgency] == "high" || doc[:importance] == "critical"
      }
    end
  end

  def determine_document_status(doc)
    # Logique simple pour déterminer le statut
    # En production, cela viendrait de la base de données
    case doc[:id]
    when "devis_rge"
      "completed"
    when "facture_finale", "pv_reception"
      "missing"
    else
      ["completed", "pending", "missing"].sample
    end
  end
end
