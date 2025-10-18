# Service pour générer les obligations techniques selon les primes sélectionnées
class DecisionHub::TechnicalRequirementsService
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
      compliance_score: calculate_compliance_rate,
      warnings: get_warnings,
      required_checks: get_required_checks,
      critical_issues: get_critical_issues,
      critical_alerts: get_critical_issues,
      obligations_by_category: get_obligations_by_category,
      recommendations: get_technical_recommendations,
      automatic_checks: get_automatic_checks,
      top_obligations: get_top_obligations
    }
  end

  private

  def get_technical_obligations
    obligations = []

    # Obligations isolation
    if has_isolation_prime?
      obligations += [
        {
          id: "resistance_thermique_toiture",
          description: "Résistance thermique R ≥ 6,0 m²K/W",
          category: "isolation_toiture",
          importance: "critical",
          status: "pending",
          details: "Minimum requis pour prime isolation toiture. Vérifier marquage CE des matériaux.",
          verification_method: "Fiche technique matériau + calcul",
          deadline: "Specification technique",
          related_primes: primes_with_category("isolation")
        },
        {
          id: "resistance_thermique_mur",
          description: "Résistance thermique R ≥ 3,5 m²K/W",
          category: "isolation_facade",
          importance: "critical",
          status: "pending",
          details: "Épaisseur minimum selon type d'isolant. Tenir compte des ponts thermiques.",
          verification_method: "Calcul thermique + épaisseur",
          deadline: "Specification technique",
          related_primes: primes_with_category("isolation")
        },
        {
          id: "pare_vapeur",
          description: "Pose pare-vapeur côté chaud",
          category: "isolation_interieure",
          importance: "high",
          status: "pending",
          details: "Éviter condensation interstitielle. Étanchéité aux raccords obligatoire.",
          verification_method: "Plan de pose + photos chantier",
          deadline: "Avant isolation",
          related_primes: primes_with_category("isolation")
        },
        {
          id: "pont_thermique",
          description: "Traitement ponts thermiques Ψ ≤ 0,15 W/mK",
          category: "isolation_generale",
          importance: "medium",
          status: "pending",
          details: "Continuité isolation aux jonctions. Calculs thermiques si requis.",
          verification_method: "Étude thermique détaillée",
          deadline: "Conception travaux",
          related_primes: primes_with_category("isolation")
        }
      ]
    end

    # Obligations ventilation
    if has_menuiserie_prime? || has_isolation_prime?
      obligations += [
        {
          id: "ventilation_chassis",
          description: "Grilles de ventilation obligatoires",
          category: "ventilation",
          importance: "high",
          status: "pending",
          details: "Débit minimum 30 m³/h par grille. Positionnement selon normes NBN.",
          verification_method: "Plan ventilation + grilles conformes",
          deadline: "Installation châssis",
          related_primes: primes_with_category("menuiserie")
        }
      ]
    end

    # Obligations chauffage
    if has_heating_prime?
      obligations += [
        {
          id: "cop_pompe_chaleur",
          description: "COP ≥ 4,0 en conditions nominales",
          category: "chauffage",
          importance: "critical",
          status: "pending",
          details: "Coefficient de performance selon EN 14511. Certification EHPA recommandée.",
          verification_method: "Fiche technique constructeur",
          deadline: "Choix équipement",
          related_primes: primes_with_category("chauffage")
        },
        {
          id: "installation_chauffage",
          description: "Installation par professionnel certifié",
          category: "chauffage",
          importance: "critical",
          status: "pending",
          details: "Installateur agréé avec garantie décennale.",
          verification_method: "Certificat installateur + assurance",
          deadline: "Choix entrepreneur",
          related_primes: primes_with_category("chauffage")
        }
      ]
    end

    # Obligations spécifiques par région
    obligations += get_region_specific_obligations

    obligations
  end

  def get_region_specific_obligations
    case @region
    when "bruxelles"
      [
        {
          id: "ventilation_bruxelles",
          description: "Système ventilation double flux",
          category: "ventilation",
          importance: "high",
          status: "pending",
          details: "Rendement ≥ 85% pour rénovation lourde si PEB < C.",
          verification_method: "Fiche technique + calcul débit",
          deadline: "Si PEB < C",
          related_primes: ["Prime Renolution"]
        },
        {
          id: "lambda_renolution",
          description: "Isolants lambda ≤ 0,04 W/mK",
          category: "isolation",
          importance: "critical",
          status: "pending",
          details: "Exigence spécifique Prime Renolution Bruxelles.",
          verification_method: "Marquage CE matériau",
          deadline: "Choix matériaux",
          related_primes: ["Prime Renolution"]
        }
      ]
    else
      [
        {
          id: "ventilation_wallonie",
          description: "Aération 3,6 m³/h par m² habitable",
          category: "ventilation",
          importance: "high",
          status: "pending",
          details: "Grilles autoréglables ou hygroréglables. Évacuation humidité.",
          verification_method: "Calcul débit + plan ventilation",
          deadline: "Post-isolation",
          related_primes: primes_with_category("isolation")
        }
      ]
    end
  end

  def get_administrative_obligations
    [
      {
        id: "entrepreneur_rge",
        description: "Entrepreneur agréé certifié",
        category: "administrative",
        importance: "critical",
        status: "completed", # Exemple
        details: "Certification RGE valide avec assurance décennale.",
        verification_method: "Certificat RGE + attestation assurance",
        deadline: "Choix entrepreneur",
        related_primes: all_primes_names
      },
      {
        id: "conformite_materiel",
        description: "Matériaux conformes normes CE",
        category: "administrative",
        importance: "critical",
        status: "pending",
        details: "Marquage CE obligatoire, fiches techniques complètes.",
        verification_method: "Marquage CE + déclarations conformité",
        deadline: "Commande matériaux",
        related_primes: all_primes_names
      }
    ]
  end

  def calculate_compliance_rate
    all_obligations = get_technical_obligations + get_administrative_obligations
    completed_count = all_obligations.count { |obs| obs[:status] == "completed" }
    total_count = all_obligations.count

    return 0 if total_count == 0
    ((completed_count.to_f / total_count) * 100).round
  end

  def get_critical_issues
    all_obligations = get_technical_obligations + get_administrative_obligations
    critical_items = all_obligations.select { |obs| obs[:importance] == "critical" && obs[:status] != "completed" }

    critical_items.map do |obs|
      {
        title: obs[:title] || obs[:description] || "Obligation critique",
        description: obs[:details] || obs[:description] || "Détails non disponibles",
        action_required: obs[:action_required] || obs[:verification_method] || "Vérification requise"
      }
    end
  end

  def get_warnings
    all_obligations = get_technical_obligations + get_administrative_obligations
    warning_items = all_obligations.select { |obs| obs[:importance] == "high" && obs[:status] != "completed" }

    warning_items.map do |obs|
      {
        title: obs[:title] || "Point d'attention",
        description: obs[:description],
        level: "high"
      }
    end
  end

  def get_technical_recommendations
    recommendations = []

    # Recommandations selon les primes
    if has_isolation_prime?
      recommendations += [
        {
          category: "isolation",
          title: "Isolants biosourcés recommandés",
          description: "Privilégier ouate cellulose, fibre bois pour meilleur déphasage",
          impact: "medium",
          benefit: "Confort été + écologie"
        },
        {
          category: "isolation",
          title: "Continuité isolation",
          description: "Traiter tous les ponts thermiques pour performance optimale",
          impact: "high",
          benefit: "Économies 15-20%"
        }
      ]
    end

    if has_heating_prime?
      recommendations += [
        {
          category: "chauffage",
          title: "Dimensionnement pompe à chaleur",
          description: "Étude thermique pour bon dimensionnement",
          impact: "high",
          benefit: "Performance + longévité"
        }
      ]
    end

    # Recommandations spécifiques région
    if @region == "bruxelles"
      recommendations << {
        category: "administrative",
        title: "Audit PAE en premier",
        description: "Obligatoire avant toute demande Renolution",
        impact: "critical",
        benefit: "Prérequis légal"
      }
    end

    recommendations
  end

  # Helpers
  def extract_selected_primes(simulation)
    DecisionHub::DataService.new(simulation).send(:extract_selected_primes)
  end

  def has_isolation_prime?
    @selected_primes.any? { |prime| prime[:category] == "isolation" }
  end

  def has_heating_prime?
    @selected_primes.any? { |prime| prime[:category] == "chauffage" }
  end

  def has_menuiserie_prime?
    @selected_primes.any? { |prime| prime[:category] == "menuiserie" }
  end

  def has_ventilation_prime?
    @selected_primes.any? { |prime| prime[:category] == "ventilation" }
  end

  def primes_with_category(category)
    @selected_primes.select { |prime| prime[:category] == category }.map { |prime| prime[:name] }
  end

  def all_primes_names
    @selected_primes.map { |prime| prime[:name] }
  end

  def get_required_checks
    [
      {
        id: "insulation_check",
        name: "Vérification isolation",
        description: "Contrôle de l'épaisseur et qualité de l'isolation",
        available: true
      },
      {
        id: "ventilation_check",
        name: "Test ventilation",
        description: "Mesure des débits de ventilation",
        available: has_ventilation_prime?
      },
      {
        id: "heating_check",
        name: "Performance chauffage",
        description: "Contrôle du rendement du système de chauffage",
        available: has_heating_prime?
      }
    ]
  end

  def get_obligations_by_category
    {
      "isolation" => {
        name: "Isolation thermique",
        icon: "house",
        compliance: 85,
        obligations: get_isolation_obligations
      },
      "ventilation" => {
        name: "Ventilation",
        icon: "wind",
        compliance: 70,
        obligations: get_ventilation_obligations
      },
      "chauffage" => {
        name: "Chauffage",
        icon: "thermometer",
        compliance: 90,
        obligations: get_heating_obligations
      }
    }
  end

  def get_isolation_obligations
    [
      {
        title: "Résistance thermique minimale",
        description: "R ≥ 4.5 m²K/W pour les murs",
        status: "compliant",
        priority: "high",
        requirements: [
          { description: "Isolation murs extérieurs", met: true },
          { description: "Continuité isolation", met: false }
        ],
        action_needed: has_isolation_prime? ? nil : "Installer isolation conforme"
      }
    ]
  end

  def get_ventilation_obligations
    [
      {
        title: "Débit de ventilation",
        description: "Renouvellement d'air conforme",
        status: has_ventilation_prime? ? "compliant" : "non_compliant",
        priority: "medium",
        requirements: [
          { description: "VMC fonctionnelle", met: has_ventilation_prime? }
        ]
      }
    ]
  end

  def get_heating_obligations
    [
      {
        title: "Rendement énergétique",
        description: "Efficacité minimale du système",
        status: has_heating_prime? ? "partial" : "non_compliant",
        priority: "high",
        requirements: [
          { description: "Chaudière haute performance", met: true },
          { description: "Régulation automatique", met: false }
        ]
      }
    ]
  end

  def get_automatic_checks
    [
      {
        id: "thermal_bridge_check",
        name: "Détection ponts thermiques",
        description: "Analyse thermographique automatique",
        available: true
      },
      {
        id: "air_tightness_check",
        name: "Test étanchéité à l'air",
        description: "Mesure automatique de perméabilité",
        available: false
      }
    ]
  end

  def get_top_obligations
    # Obtenir toutes les obligations et sélectionner les 5 plus importantes
    all_obligations = get_technical_obligations

    # Trier par importance (critical > high > medium)
    priority_order = { "critical" => 3, "high" => 2, "medium" => 1 }

    top_5 = all_obligations.sort_by { |ob| -priority_order[ob[:importance]] }
                          .first(5)

    # Formatter pour l'affichage compact
    top_5.map do |obligation|
      {
        name: obligation[:description].truncate(40),
        category: obligation[:category],
        importance: obligation[:importance],
        status: determine_obligation_status(obligation),
        critical: obligation[:importance] == "critical"
      }
    end
  end

  def determine_obligation_status(obligation)
    # Logique simple pour déterminer le statut
    # En production, cela viendrait de la base de données
    case obligation[:id]
    when "resistance_thermique_toiture", "resistance_thermique_mur"
      "verified"
    when "ventilation_conformity", "heating_efficiency"
      "pending"
    else
      ["verified", "pending", "missing"].sample
    end
  end
end
