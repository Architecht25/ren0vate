module PageTracking
  extend ActiveSupport::Concern

  private

  # Track une visite de page
  def track_page_visit(page_name, options = {})
    return if Rails.env.test?  # Pas de tracking en test

    # Détecter automatiquement la région depuis la route
    region = detect_region_from_path

    # Détecter le type de page
    page_type = detect_page_type(page_name)

    PageVisit.track_visit(
      page_name: page_name,
      request: request,
      user: current_user,
      region: options[:region] || region,
      page_type: options[:page_type] || page_type
    )
  end

  # Détecte la région depuis l'URL
  def detect_region_from_path
    case request.path
    when /bruxelles/i
      'Bruxelles'
    when /wallonie/i
      'Wallonie'
    when /flandre/i
      'Flandre'
    else
      'Général'
    end
  end

  # Détecte le type de page depuis le nom
  def detect_page_type(page_name)
    case page_name.downcase
    when /simulation/
      'simulation'
    when /entreprise/
      'entreprise'
    when /particulier/
      'particulier'
    when /home|accueil/
      'accueil'
    when /contact/
      'contact'
    else
      'autre'
    end
  end

  # Helper pour tracker les simulations spécifiquement
  def track_simulation_visit(simulator_type, region = nil)
    track_page_visit(
      "simulation_#{simulator_type}",
      region: region,
      page_type: 'simulation'
    )
  end
end
