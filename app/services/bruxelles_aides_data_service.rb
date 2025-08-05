class BruxellesAidesDataService
  # Données complètes des aides aux entreprises bruxelloises
  # Source: economie-emploi.brussels

  def self.get_all_categories
    {
      transition_economique: {
        name: "Transition économique",
        icon: "🌱",
        description: "Accompagnement vers la transition sociale, environnementale et numérique",
        color: "success",
        aides: get_transition_economique_aides
      },
      investissements: {
        name: "Investissements",
        icon: "🏭",
        description: "Soutien aux investissements matériels et immobiliers",
        color: "primary",
        aides: get_investissements_aides
      },
      recrutement_formation: {
        name: "Recrutement et formation",
        icon: "👥",
        description: "Aides à l'embauche et formation du personnel",
        color: "info",
        aides: get_recrutement_formation_aides
      },
      expertise_services: {
        name: "Expertise et services externes",
        icon: "🎯",
        description: "Consultance générale, études et audits",
        color: "warning",
        aides: get_expertise_services_aides
      },
      nuisances_chantier: {
        name: "Nuisances chantier",
        icon: "🚧",
        description: "Dédommagement pour impact de chantiers publics",
        color: "orange",
        aides: get_nuisances_chantier_aides
      },
      exportation: {
        name: "Exportation",
        icon: "🌍",
        description: "Primes temporairement suspendues",
        color: "secondary",
        aides: get_exportation_aides
      }
    }
  end

  def self.get_category_details(category_key)
    categories = get_all_categories
    categories[category_key.to_sym] || {}
  end

  private

  def self.get_transition_economique_aides
    [
      {
        name: "Prime de consultance en transition économique",
        description: "Accompagnement par un consultant spécialisé pour la transition sociale, environnementale ou numérique",
        taux: "50%",
        plafond: "15.000€ par année civile",
        duree_min: "20 jours minimum",
        conditions: [
          "Consultant agréé par Bruxelles Economie et Emploi",
          "Mission de minimum 20 jours",
          "Domaines éligibles: transition environnementale, sociale, numérique"
        ],
        exemples: [
          "Audit énergétique et plan d'action",
          "Stratégie de développement durable",
          "Digitalisation des processus",
          "Responsabilité sociétale des entreprises (RSE)"
        ],
        documents: [
          "Demande de principe (avant signature du contrat)",
          "Contrat de consultance",
          "Rapport final du consultant",
          "Factures acquittées"
        ]
      },
      {
        name: "Prime d'investissement en transition économique",
        description: "Investissements matériels et immatériels pour la transition",
        taux: "20% à 40%",
        plafond: "Selon type d'investissement",
        conditions: [
          "Investissement minimum de 5.000€",
          "Lien direct avec la transition économique",
          "Matériel neuf ou récent (max 2 ans)"
        ],
        exemples: [
          "Équipements économes en énergie",
          "Technologies vertes",
          "Outils numériques",
          "Matériel de recyclage"
        ]
      },
      {
        name: "Prime mobilité basses émissions",
        description: "Investissements pour une mobilité plus respectueuse de l'environnement",
        taux: "20% à 40%",
        plafond: "Variable selon équipement",
        conditions: [
          "Véhicules électriques ou hybrides",
          "Infrastructure de recharge",
          "Équipements de mobilité douce"
        ],
        exemples: [
          "Véhicules électriques utilitaires",
          "Bornes de recharge",
          "Vélos et trottinettes électriques",
          "Infrastructure cyclable"
        ]
      },
      {
        name: "Prime accessibilité des lieux",
        description: "Amélioration de l'accessibilité pour les personnes à mobilité réduite",
        taux: "50%",
        plafond: "15.000€ par période de 3 ans",
        conditions: [
          "Amélioration concrète de l'accessibilité",
          "Respect des normes PMR",
          "Audit préalable recommandé"
        ],
        exemples: [
          "Rampes d'accès",
          "Ascenseurs adaptés",
          "Toilettes PMR",
          "Signalétique adaptée"
        ]
      }
    ]
  end

  def self.get_investissements_aides
    [
      {
        name: "Prime d'investissement - Matériel et équipement",
        description: "Acquisition de matériel professionnel et équipement de production",
        taux: "20% (micro), 15% (petite), 10% (moyenne)",
        plafond: "200.000€ par période de 3 ans",
        conditions: [
          "Investissement minimum de 5.000€",
          "Matériel neuf ou d'occasion récente (max 3 ans)",
          "Usage professionnel exclusif"
        ],
        exemples: [
          "Machines de production",
          "Équipements informatiques",
          "Mobilier professionnel",
          "Véhicules utilitaires"
        ]
      },
      {
        name: "Prime d'investissement - Travaux",
        description: "Travaux d'aménagement, rénovation et construction",
        taux: "20% à 40%",
        plafond: "Variable selon type",
        conditions: [
          "Investissement minimum de 5.000€",
          "Travaux réalisés par entrepreneur agréé",
          "Respect des normes urbanistiques"
        ],
        exemples: [
          "Rénovation de locaux",
          "Aménagement d'espaces",
          "Installation électrique",
          "Isolation et économies d'énergie"
        ]
      },
      {
        name: "Prime d'investissement - Immobilier",
        description: "Acquisition et aménagement de biens immobiliers",
        taux: "10% à 20%",
        plafond: "75.000€ par bien",
        conditions: [
          "Bien situé en Région bruxelloise",
          "Usage professionnel minimum 5 ans",
          "Première acquisition par l'entreprise"
        ],
        exemples: [
          "Acquisition de bureaux",
          "Achat d'entrepôts",
          "Locaux commerciaux",
          "Ateliers de production"
        ]
      },
      {
        name: "Prime de conformité, sécurisation et accessibilité",
        description: "Mise en conformité réglementaire et amélioration de l'accessibilité",
        taux: "50%",
        plafond: "15.000€ par période de 3 ans",
        conditions: [
          "Obligation légale ou réglementaire",
          "Amélioration de l'accessibilité PMR",
          "Certification par organisme agréé"
        ],
        exemples: [
          "Mise aux normes de sécurité",
          "Accessibilité PMR",
          "Conformité HACCP",
          "Normes environnementales"
        ]
      }
    ]
  end

  def self.get_recrutement_formation_aides
    [
      {
        name: "Prime de recrutement - Demandeurs d'emploi",
        description: "Aide à l'embauche de demandeurs d'emploi bruxellois",
        taux: "Montant forfaitaire",
        plafond: "2.500€ à 7.500€ selon profil",
        duree: "CDI ou CDD minimum 6 mois",
        conditions: [
          "Demandeur d'emploi inscrit à Actiris",
          "Contrat minimum 19h/semaine",
          "Maintien de l'emploi minimum 1 an"
        ],
        exemples: [
          "Jeunes demandeurs d'emploi",
          "Demandeurs d'emploi longue durée",
          "Publics fragilisés",
          "Profils techniques recherchés"
        ]
      },
      {
        name: "Prime de formation du personnel",
        description: "Financement de la formation continue des employés",
        taux: "50%",
        plafond: "15.000€ par année civile",
        conditions: [
          "Formation certifiante ou qualifiante",
          "Organisme de formation agréé",
          "Lien avec l'activité professionnelle"
        ],
        exemples: [
          "Formations techniques spécialisées",
          "Langues étrangères",
          "Compétences numériques",
          "Management et leadership"
        ]
      },
      {
        name: "Prime de stage en entreprise",
        description: "Encouragement à l'accueil de stagiaires",
        taux: "Forfaitaire",
        plafond: "1.250€ par stagiaire",
        duree: "Stage minimum 3 mois",
        conditions: [
          "Convention de stage tripartite",
          "Stagiaire domicilié en Région bruxelloise",
          "Encadrement qualifié"
        ],
        exemples: [
          "Stages étudiants",
          "Stages d'insertion professionnelle",
          "Stages de reconversion",
          "Stages techniques spécialisés"
        ]
      }
    ]
  end

  def self.get_expertise_services_aides
    [
      {
        name: "Prime de consultance générale",
        description: "Accompagnement par un consultant externe",
        taux: "50%",
        plafond: "15.000€ par année civile",
        duree: "Mission minimum 10 jours",
        conditions: [
          "Consultant externe à l'entreprise",
          "Mission minimum 10 jours ouvrables",
          "Rapport de mission détaillé"
        ],
        exemples: [
          "Étude de marché",
          "Plan d'affaires",
          "Stratégie commerciale",
          "Organisation interne"
        ]
      },
      {
        name: "Prime d'audit et certification",
        description: "Audits qualité et certifications professionnelles",
        taux: "50%",
        plafond: "7.500€ par certification",
        conditions: [
          "Organisme certificateur agréé",
          "Certification reconnue internationalement",
          "Première certification ou renouvellement"
        ],
        exemples: [
          "ISO 9001 (Qualité)",
          "ISO 14001 (Environnement)",
          "ISO 45001 (Sécurité)",
          "Certifications sectorielles"
        ]
      },
      {
        name: "Prime d'étude de faisabilité",
        description: "Études préalables aux investissements importants",
        taux: "50%",
        plafond: "10.000€ par étude",
        conditions: [
          "Étude préalable à un investissement",
          "Bureau d'études spécialisé",
          "Rapport technique détaillé"
        ],
        exemples: [
          "Étude de faisabilité technique",
          "Analyse de rentabilité",
          "Étude d'impact environnemental",
          "Analyse des risques"
        ]
      }
    ]
  end

  def self.get_nuisances_chantier_aides
    [
      {
        name: "Prime de nuisances chantier - Commerce",
        description: "Dédommagement pour commerçants impactés par les chantiers publics",
        taux: "Forfaitaire",
        plafond: "Selon ampleur des nuisances",
        duree: "Pendant la durée du chantier",
        conditions: [
          "Commerce situé dans la zone de chantier",
          "Chantier public ou d'utilité publique",
          "Impact démontrable sur l'activité"
        ],
        exemples: [
          "Rénovation de voirie",
          "Travaux de métro/tram",
          "Chantiers d'utilité publique",
          "Aménagements urbains"
        ]
      },
      {
        name: "Prime de nuisances chantier - HoReCa",
        description: "Soutien spécifique aux établissements HoReCa",
        taux: "Majoré",
        plafond: "Selon perte de chiffre d'affaires",
        conditions: [
          "Établissement HoReCa agré",
          "Baisse prouvée du chiffre d'affaires",
          "Impossibilité de déplacement"
        ],
        exemples: [
          "Restaurants",
          "Cafés et bars",
          "Hôtels",
          "Traiteurs"
        ]
      }
    ]
  end

  def self.get_exportation_aides
    [
      {
        name: "Primes d'exportation",
        description: "Primes temporairement suspendues - en cours de révision",
        taux: "N/A",
        plafond: "N/A",
        statut: "Suspendu",
        conditions: [
          "Dispositif en cours de révision",
          "Nouvelles modalités à venir",
          "Consulter le site officiel pour les mises à jour"
        ],
        exemples: [
          "Prospection de marchés étrangers",
          "Participation à foires internationales",
          "Missions commerciales",
          "Adaptation de produits à l'export"
        ],
        info: "Les primes d'exportation sont temporairement suspendues. De nouvelles modalités sont en cours d'élaboration. Consultez régulièrement le site economie-emploi.brussels pour les dernières mises à jour."
      }
    ]
  end
end
