class Documents::ConditionalDisplayService
  def initialize(property, simulation_data = nil)
    @property = property
    @simulation_data = simulation_data
  end

  # Détermine si le permis d'urbanisme est requis
  def requires_urban_permit?
    return false unless @property&.project_cards&.any?

    # Vérifier si un permis est mentionné dans les cartes projet
    @property.project_cards.any? do |card|
      card.dig('permis_requis') == true ||
      card.dig('description')&.match?(/permis|urbanisme/i) ||
      card.dig('surface_travaux').to_i > 30 # Seuil indicatif
    end
  end

  # Détermine si le certificat PEB est requis
  def requires_peb_certificate?
    # Toujours obligatoire pour les biens résidentiels
    @property&.is_residential? || @property&.property_type&.match?(/maison|appartement|studio/i)
  end

  # Détermine si l'audit énergétique est requis
  def requires_energy_audit?
    return false unless @simulation_data

    # Si simulation contient des primes énergétiques
    energy_primes = @simulation_data.dig('primes')&.select do |prime|
      prime.dig('category')&.match?(/energie|isolation|chauffage/i)
    end

    energy_primes&.any?
  end

  # Détermine si les documents électriques sont requis
  def requires_electrical_documents?
    return false unless @simulation_data

    # Si travaux électriques détectés
    @simulation_data.dig('primes')&.any? do |prime|
      prime.dig('title')&.match?(/électriq|electric/i) ||
      prime.dig('description')&.match?(/installation électrique/i)
    end
  end

  # Détermine si les documents de sécurité incendie sont requis
  def requires_fire_safety_documents?
    return false unless @property

    # Pour les entreprises ou bâtiments publics
    @property.is_entreprise? ||
    @property.property_type&.match?(/bureau|commerce|restaurant/i)
  end

  # Détermine si les documents spécifiques à la région sont requis
  def requires_regional_documents?
    {
      wallonie: @property&.is_wallonie?,
      brussels: @property&.is_brussels?,
      flanders: @property&.is_flanders?
    }
  end

  # Méthode principale pour obtenir tous les conditionnels
  def get_conditional_requirements
    {
      urban_permit: requires_urban_permit?,
      peb_certificate: requires_peb_certificate?,
      energy_audit: requires_energy_audit?,
      electrical_documents: requires_electrical_documents?,
      fire_safety: requires_fire_safety_documents?,
      regional: requires_regional_documents?
    }
  end

  private

  # Helper pour vérifier le type de bien
  def residential_property?
    @property&.property_type&.match?(/maison|appartement|studio|villa/i)
  end

  # Helper pour vérifier les seuils de surface
  def exceeds_surface_threshold?(threshold = 30)
    total_surface = @property&.project_cards&.sum do |card|
      card.dig('surface_travaux').to_i
    end

    total_surface > threshold
  end
end
