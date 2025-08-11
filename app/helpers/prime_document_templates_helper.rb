module PrimeDocumentTemplatesHelper
  # Récupère les documents disponibles pour une simulation
  def documents_for_simulation(simulation)
    return [] unless simulation&.persisted?

    # Récupérer les primes sélectionnées (à adapter selon votre logique)
    selected_primes = get_simulation_primes(simulation)

    if selected_primes.any?
      PrimeDocumentTemplate.joins(:prime)
                           .where(prime: selected_primes)
                           .required_docs
                           .by_order
                           .includes(:prime)
    else
      []
    end
  end

  # Récupère les documents disponibles pour une liste de primes
  def documents_for_primes(primes)
    return [] if primes.blank?

    PrimeDocumentTemplate.joins(:prime)
                         .where(prime: primes)
                         .required_docs
                         .by_order
                         .includes(:prime)
  end

  # Compte le nombre de documents disponibles pour une simulation
  def documents_count_for_simulation(simulation)
    documents_for_simulation(simulation).count
  end

  # Vérifie si des documents sont disponibles pour une simulation
  def documents_available_for_simulation?(simulation)
    documents_count_for_simulation(simulation) > 0
  end

  # Génère l'URL de téléchargement groupé pour une simulation
  def download_all_documents_url(simulation)
    if documents_available_for_simulation?(simulation)
      download_documents_simulation_path(simulation)
    else
      nil
    end
  end

  # Formate le nom de fichier pour le téléchargement
  def format_document_filename(template)
    "#{template.prime.slug}_#{template.type_document}.pdf"
  end

  # Retourne une icône selon le type de document
  def document_type_icon(type_document)
    case type_document.to_s
    when 'attestation_entrepreneur'
      'bi-person-check'
    when 'formulaire_demande'
      'bi-file-earmark-text'
    when 'annexe_technique'
      'bi-gear'
    when 'guide_remplissage'
      'bi-book'
    when 'certificat_conformite'
      'bi-award'
    when 'fiche_technique'
      'bi-tools'
    else
      'bi-file-earmark-pdf'
    end
  end

  # Retourne une couleur selon le type de document
  def document_type_color(type_document)
    case type_document.to_s
    when 'attestation_entrepreneur'
      'primary'
    when 'formulaire_demande'
      'success'
    when 'annexe_technique'
      'info'
    when 'guide_remplissage'
      'warning'
    when 'certificat_conformite'
      'success'
    when 'fiche_technique'
      'secondary'
    else
      'dark'
    end
  end

  # Badge HTML pour le type de document
  def document_type_badge(type_document)
    color = document_type_color(type_document)
    icon = document_type_icon(type_document)
    text = type_document.humanize

    content_tag :span, class: "badge bg-#{color}" do
      content_tag(:i, '', class: "#{icon} me-1") + text
    end
  end

  # Message d'aide selon le type de document
  def document_help_text(type_document)
    case type_document.to_s
    when 'attestation_entrepreneur'
      "Document à faire remplir et signer par votre entrepreneur"
    when 'formulaire_demande'
      "Formulaire officiel de demande de prime à compléter"
    when 'annexe_technique'
      "Spécifications techniques à respecter pour les travaux"
    when 'guide_remplissage'
      "Guide pour vous aider à remplir correctement les formulaires"
    when 'certificat_conformite'
      "Certificat attestant de la conformité des travaux"
    when 'fiche_technique'
      "Fiche technique détaillée du matériel/équipement"
    else
      "Document officiel requis pour votre dossier de prime"
    end
  end

  private

  # Méthode pour récupérer les primes d'une simulation
  # À adapter selon votre logique métier
  def get_simulation_primes(simulation)
    if simulation.respond_to?(:selected_primes)
      simulation.selected_primes
    elsif simulation.respond_to?(:simulation_prime_cards)
      simulation.simulation_prime_cards.includes(:prime).map(&:prime)
    else
      # Logique alternative ou fallback
      []
    end
  end
end
