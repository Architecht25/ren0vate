# =====================================================
# AIDES BRUXELLES ENTREPRISES - TRANSITION ÉCONOMIQUE + MOBILITÉ
# =====================================================
# 5 aides: transition_consultance, investissements_transition_economique,
#          mobilite_velo_cargo, mobilite_utilitaire_electrique, mobilite_utilitaire_retrofit
# =====================================================

puts "🌱 Création des aides Transition économique & Mobilité..."

# Prime Transition Consultance
EntrepriseAide.find_or_create_by(slug: "bruxelles_transition_consultance") do |aide|
  aide.titre = "Prime Transition Consultance"
  aide.region = "bruxelles"
  aide.categorie = "transition_economique"
  aide.description = "Prime pour financer des missions de consultance en transition économique dans les domaines environnemental, social et de gouvernance participative"

  aide.secteurs_eligibles = [
    "Tous secteurs d'activité éligibles selon codes NACE-BEL 2025",
    "Exclusions: secteurs NACE spécifiés par l'administration",
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale"
  ]

  aide.tailles_eligibles = ["tpe", "pme"] # TPE et PME uniquement

  aide.montant_min = 500  # Intervention minimum par mission
  aide.montant_max = 15000 # Maximum par année civile
  aide.taux_aide = 50.0 # Taux de base, majorations possibles jusqu'à 80%

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Demande avant début de mission"
    ],
    "mission" => [
      "Domaines éligibles: plan diversité, gouvernance participative, bien-être travail, stratégie environnementale/sociale, outils mesure impact, audit label, audit énergétique",
      "Caractère exceptionnel (pas de sous-traitance régulière)",
      "Durée maximum 6 mois",
      "Minimum 5 travailleurs pour gouvernance participative"
    ],
    "consultant" => [
      "Activité principale = conseil dans domaine concerné",
      "Spécialisé dans le domaine",
      "Minimum 2 ans d'expérience",
      "Références et compétences prouvées",
      "Indépendant de l'entreprise",
      "Maximum 2 missions subsidiées par entreprise sur 2 ans",
      "Facturation directe à l'entreprise"
    ]
  }

  aide.documents_requis = {
    "demande_consultance" => [
      "Demande via MonBEE avant début mission",
      "Annexes spécifiques consultance transition",
      "Devis détaillé du consultant",
      "CV et références du consultant"
    ],
    "demande_label" => [
      "Demande via MonBEE avant première facture",
      "Annexes spécifiques labels et certificats",
      "Documentation sur le label visé"
    ],
    "justificatifs" => [
      "Factures acquittées",
      "Rapport final de mission",
      "Preuves de mise en œuvre recommandations",
      "Déclaration de créance complétée"
    ]
  }

  aide.modalites_paiement = {
    "taux_base" => "50% des dépenses éligibles",
    "plafond_max" => "80% avec majorations",
    "majorations" => {
      "starter_micro" => "+15%",
      "starter_petite" => "+10%",
      "exemplaire_environnemental_micro" => "+15%",
      "exemplaire_environnemental_petite" => "+10%",
      "exemplaire_social_micro" => "+15%",
      "exemplaire_social_petite" => "+10%"
    },
    "limites" => {
      "montant_max_annuel" => "15.000€",
      "missions_max_annuel" => "3 missions",
      "intervention_minimum" => "500€"
    }
  }

  aide.delais_procedures = {
    "demande" => "Au plus tard la veille du début de mission",
    "demande_label" => "Au plus tard la veille de première facture",
    "debut_mission" => "Lendemain introduction demande minimum, 3 mois après octroi maximum",
    "decision_administration" => "4 mois maximum après demande complète",
    "envoi_justificatifs" => "15 mois après notification d'octroi",
    "paiement" => "Une fois après contrôle justificatifs"
  }

  aide.url_officielle = "https://economie-emploi.brussels/prime-transition-consultance"
  aide.statut = "active"
end

# Prime Investissements Transition Économique
EntrepriseAide.find_or_create_by(slug: "bruxelles_investissements_transition_economique") do |aide|
  aide.titre = "Prime Investissements dans le cadre de la transition économique"
  aide.region = "bruxelles"
  aide.categorie = "transition_economique"
  aide.description = "Prime pour l'aménagement ou l'achat de machines et équipements visant l'efficacité énergétique et l'optimisation des ressources"

  aide.secteurs_eligibles = [
    "Tous secteurs d'activité éligibles selon codes NACE-BEL 2025",
    "Exclusions: secteurs NACE spécifiés par l'administration",
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale"
  ]

  aide.tailles_eligibles = ["tpe", "pme"] # TPE et PME uniquement

  aide.montant_min = 2000  # Investissement minimum
  aide.montant_max = 50000 # Maximum par année civile
  aide.taux_aide = 30.0 # Taux de base, majorations possibles jusqu'à 50%

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Demande avant début du programme d'investissements"
    ],
    "investissements_eligibles" => [
      "Renouvellement installations d'éclairage LED",
      "Gestion temporelle ou présentielle des luminaires",
      "Optimisation température bâtiment (portes fermeture automatique)",
      "Remplacement machines/équipements moins performants énergétiquement",
      "Réduction significative consommation matières premières"
    ],
    "conditions_techniques" => [
      "Montant minimum 2000€ par investissement",
      "Classe efficacité énergétique selon annexe 3 (si étiquetage obligatoire)",
      "Attestation installateur/fournisseur (si pas d'étiquetage)",
      "Économie significative d'énergie/électricité/matières premières",
      "Facture minimum 500€ HTVA",
      "Maximum 2 investissements par année civile"
    ],
    "delais" => [
      "Réalisation et paiement sous 12 mois après notification d'octroi"
    ]
  }

  aide.documents_requis = {
    "demande" => [
      "Demande via MonBEE avant début investissements",
      "Attestation bancaire (RIB)",
      "Copie du mandat (le cas échéant)",
      "Preuve exemplarité sociale (si applicable)",
      "Preuve exemplarité environnementale (si applicable)",
      "Devis détaillés des investissements"
    ],
    "investissements_avec_etiquetage" => [
      "Justification classe efficacité énergétique selon annexe 3"
    ],
    "investissements_sans_etiquetage" => [
      "Attestation installateur/fournisseur selon modèle officiel",
      "Justification économie significative ressources"
    ],
    "justificatifs" => [
      "Factures acquittées (min 500€ HTVA)",
      "Preuves de paiement",
      "Preuves d'installation/mise en service",
      "Déclaration de créance complétée"
    ]
  }

  aide.modalites_paiement = {
    "taux_base" => "30% des dépenses éligibles",
    "plafond_max" => "50% avec majorations",
    "majorations" => {
      "starter" => "+10%",
      "exemplaire_environnemental" => "+10%",
      "exemplaire_social" => "+10%"
    },
    "limites" => {
      "montant_max_annuel" => "50.000€",
      "investissements_max_annuel" => "2 investissements",
      "facture_minimum" => "500€ HTVA"
    }
  }

  aide.delais_procedures = {
    "demande" => "Avant mise en œuvre du programme d'investissements",
    "decision_administration" => "4 mois maximum après demande complète",
    "realisation_investissements" => "12 mois maximum après notification d'octroi",
    "envoi_justificatifs" => "15 mois après notification de décision d'octroi",
    "paiement" => "Une fois après contrôle justificatifs"
  }

  aide.url_officielle = "https://economie-emploi.brussels/prime-investissements-transition-economique"
  aide.statut = "active"
end

# Prime Mobilité Vélo-cargo
EntrepriseAide.find_or_create_by(slug: "bruxelles_mobilite_velo_cargo") do |aide|
  aide.titre = "Prime Mobilité - Vélo-cargo ou remorque"
  aide.region = "bruxelles"
  aide.categorie = "transition_economique"
  aide.description = "Prime pour l'acquisition de vélos-cargo ou remorques-vélo dans le cadre d'une mobilité basses émissions pour diminuer les émissions de CO2"

  aide.secteurs_eligibles = [
    "Tous secteurs d'activité éligibles selon codes NACE-BEL 2025",
    "Exclusions: secteurs NACE spécifiés par l'administration",
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale"
  ]

  aide.tailles_eligibles = ["tpe", "pme"] # TPE et PME uniquement

  aide.montant_min = 500   # Facture minimum
  aide.montant_max = 4000  # Maximum par vélo-cargo (2000€ par remorque-vélo)
  aide.taux_aide = 40.0    # Taux de base, majorations possibles jusqu'à 70%

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Demande dans les 6 mois de la date de facture d'achat"
    ],
    "vehicules_eligibles" => [
      "Vélo-cargo: cycles et cycles motorisés électriques pour transport fret",
      "Conteneur ou plateforme intégrée avec charge utile minimum 100kg",
      "Assistance électrique max 250W interrompue à 25km/h (si motorisé)",
      "Remorque-vélo: remorques utilitaires pour marchandise",
      "Charge utile minimum 50kg pour remorque-vélo"
    ],
    "conditions_techniques" => [
      "Facture minimum 500€",
      "Maximum 3 vélos-cargo/remorques par année civile",
      "Maximum 12.000€ total par bénéficiaire par année civile",
      "Vélo-cargo: max 4000€ de prime",
      "Remorque-vélo: max 2000€ de prime"
    ]
  }

  aide.documents_requis = {
    "demande" => [
      "Demande via MonBEE dans les 6 mois de la facture",
      "Attestation bancaire (RIB)",
      "Copie du mandat (le cas échéant)",
      "Facture d'achat du vélo-cargo et/ou remorque-vélo",
      "Documentation technique du véhicule",
      "Preuve exemplarité sociale (si applicable)",
      "Preuve exemplarité environnementale (si applicable)"
    ],
    "justificatifs" => [
      "Pièces justificatives sous 6 mois après notification d'octroi",
      "Preuves d'utilisation du véhicule"
    ]
  }

  aide.modalites_paiement = {
    "taux_base" => "40% des dépenses éligibles",
    "plafond_max" => "70% avec majorations",
    "majorations" => {
      "starter" => "+10%",
      "exemplaire_environnemental" => "+10%",
      "exemplaire_social" => "+10%"
    },
    "limites" => {
      "montant_max_velo_cargo" => "4.000€",
      "montant_max_remorque" => "2.000€",
      "montant_max_annuel_total" => "3×4.000€/an",
      "vehicules_max_annuel" => "3 vélos-cargo/remorques",
      "facture_minimum" => "500€"
    }
  }

  aide.delais_procedures = {
    "demande" => "Dans les 6 mois de la date de facture d'achat",
    "decision_administration" => "4 mois après demande complète",
    "envoi_justificatifs" => "6 mois après notification de décision d'octroi",
    "paiement" => "Après contrôle justificatifs"
  }

  aide.url_officielle = "https://economie-emploi.brussels/prime-mobilite-velo-cargo"
  aide.statut = "active"
end

# Prime Mobilité Utilitaire Électrique
EntrepriseAide.find_or_create_by(slug: "bruxelles_mobilite_utilitaire_electrique") do |aide|
  aide.titre = "Prime Mobilité - Utilitaire électrique"
  aide.region = "bruxelles"
  aide.categorie = "transition_economique"
  aide.description = "Prime pour l'acquisition d'utilitaires professionnels électriques dans le cadre d'une mobilité basses émissions, incluant optionnellement une borne de recharge"

  aide.secteurs_eligibles = [
    "Tous secteurs d'activité éligibles selon codes NACE-BEL 2025",
    "Exclusions: secteurs NACE spécifiés par l'administration",
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale"
  ]

  aide.tailles_eligibles = ["tpe", "pme"] # TPE et PME uniquement

  aide.montant_min = 500   # Facture minimum HTVA
  aide.montant_max = 16000 # Maximum par utilitaire électrique (y compris borne)
  aide.taux_aide = 5.0     # Taux de base, majorations possibles jusqu'à 40%

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Demande dans les 6 mois de la date de facture d'achat véhicule"
    ],
    "vehicules_eligibles" => [
      "Véhicule catégorie N1 à motorisation exclusivement électrique",
      "Véhicule catégorie L7e-CU à motorisation exclusivement électrique",
      "Conformité aux normes d'émission européennes applicables",
      "Pas de montant minimum d'investissement"
    ],
    "borne_recharge" => [
      "Acquisition et installation possibles dans même demande",
      "Factures borne max 3 mois avant facture véhicule",
      "Incluse dans plafond de 16.000€ par véhicule"
    ],
    "conditions_techniques" => [
      "Facture minimum 500€ HTVA",
      "Maximum 3 véhicules électriques par année civile",
      "Maximum 3 bornes de recharge par année civile",
      "Maximum 48.000€ total par bénéficiaire par année civile"
    ]
  }

  aide.documents_requis = {
    "demande" => [
      "Demande via MonBEE dans les 6 mois de la facture véhicule",
      "Attestation bancaire (RIB)",
      "Copie du mandat (le cas échéant)",
      "Facture d'achat du véhicule électrique",
      "Certificat de conformité ou carte grise",
      "Factures borne de recharge (si applicable)",
      "Preuve exemplarité sociale (si applicable)",
      "Preuve exemplarité environnementale (si applicable)",
      "Preuve remplacement véhicule zone basses émissions (si applicable)"
    ],
    "justificatifs" => [
      "Pièces justificatives sous 15 mois après notification d'octroi",
      "Déclaration de créance complétée",
      "Preuves d'utilisation du véhicule"
    ]
  }

  aide.modalites_paiement = {
    "taux_base" => "5% des dépenses éligibles",
    "plafond_max" => "40% avec majorations",
    "majorations" => {
      "remplacement_zone_basses_emissions" => "+35%",
      "starter" => "+10%",
      "exemplaire_environnemental" => "+10%",
      "exemplaire_social" => "+10%"
    },
    "exemples" => {
      "base_seule" => "5% (aucun critère)",
      "starter" => "15% (5% + 10%)",
      "exemplaire_double" => "25% (5% + 10% + 10%)",
      "remplacement_zone" => "40% (5% + 35%)"
    },
    "limites" => {
      "montant_max_vehicule" => "16.000€ (y compris borne)",
      "montant_max_annuel_total" => "48.000€",
      "vehicules_max_annuel" => "3 véhicules électriques",
      "bornes_max_annuel" => "3 bornes de recharge",
      "facture_minimum" => "500€ HTVA"
    }
  }

  aide.delais_procedures = {
    "demande" => "Dans les 6 mois de la date de facture d'achat véhicule",
    "borne_recharge" => "Factures borne max 3 mois avant facture véhicule",
    "decision_administration" => "4 mois après demande complète",
    "envoi_justificatifs" => "15 mois après notification de décision d'octroi",
    "paiement" => "En une fois après contrôle justificatifs"
  }

  aide.url_officielle = "https://economie-emploi.brussels/prime-mobilite-utilitaire-electrique"
  aide.statut = "active"
end

# Prime Mobilité Utilitaire Rétrofit
EntrepriseAide.find_or_create_by(slug: "bruxelles_mobilite_utilitaire_retrofit") do |aide|
  aide.titre = "Prime Mobilité - Utilitaire rétrofit"
  aide.region = "bruxelles"
  aide.categorie = "transition_economique"
  aide.description = "Prime pour le remplacement ou la transformation d'anciens véhicules thermiques en utilitaires électriques (rétrofit), incluant optionnellement une borne de recharge"

  aide.secteurs_eligibles = [
    "Tous secteurs d'activité éligibles selon codes NACE-BEL 2025",
    "Exclusions: secteurs NACE spécifiés par l'administration",
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale"
  ]

  aide.tailles_eligibles = ["tpe", "pme"] # TPE et PME uniquement

  aide.montant_min = 500   # Facture minimum
  aide.montant_max = 16000 # Maximum par véhicule transformé (y compris borne)
  aide.taux_aide = 5.0     # Taux de base, majorations possibles jusqu'à 70% !

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Demande dans les 6 mois de la facture achat/transformation"
    ],
    "transformation_retrofit" => [
      "Transformation moteur thermique vers électrique",
      "Réalisée par professionnel autorisé",
      "Utilitaire rétrofit homologué comme utilitaire électrique",
      "Conforme à la réglementation applicable"
    ],
    "immatriculation" => [
      "Véhicules immatriculés dans la Région (si obligation)",
      "Exception: immatriculation au nom entreprise crédit-bail"
    ],
    "borne_recharge" => [
      "Acquisition et installation possibles dans même demande",
      "Factures borne max 3 mois avant facture véhicule/transformation",
      "Incluse dans plafond de 16.000€ par véhicule"
    ],
    "conditions_techniques" => [
      "Facture minimum 500€",
      "Maximum 3 véhicules électriques/retrofit par année civile",
      "Maximum 3 bornes de recharge par année civile",
      "Maximum 48.000€ total par bénéficiaire par année civile"
    ]
  }

  aide.documents_requis = {
    "demande" => [
      "Demande via MonBEE dans les 6 mois facture achat/transformation",
      "Attestation bancaire (RIB)",
      "Copie du mandat (le cas échéant)",
      "Avis de radiation véhicule remplacé",
      "Certificat d'immatriculation véhicule remplacé (si applicable)",
      "Certificat d'immatriculation véhicule acquis (si applicable)",
      "Facture d'achat du véhicule (si applicable)",
      "Facture du retrofit (si applicable)",
      "Certificat d'immatriculation véhicule transformé (si applicable)",
      "Preuve transformation rétrofit effectuée (si applicable)",
      "Preuve homologation véhicule retrofité (si applicable)",
      "Factures borne de recharge (si applicable)",
      "Preuve exemplarité sociale (si applicable)",
      "Preuve exemplarité environnementale (si applicable)",
      "Preuve critères zone basses émissions (si applicable)"
    ],
    "justificatifs" => [
      "Pièces justificatives sous 15 mois après notification d'octroi",
      "Déclaration de créance complétée",
      "Preuves d'utilisation du véhicule transformé"
    ]
  }

  aide.modalites_paiement = {
    "taux_base" => "5% des dépenses éligibles",
    "plafond_max" => "70% avec majorations cumulées (cas exceptionnel)",
    "majorations" => {
      "remplacement_zone_basses_emissions" => "+35%",
      "starter" => "+10%",
      "exemplaire_environnemental" => "+10%",
      "exemplaire_social" => "+10%"
    },
    "exemples" => {
      "base_seule" => "5% (aucun critère)",
      "starter" => "15% (5% + 10%)",
      "exemplaire_double" => "25% (5% + 10% + 10%)",
      "remplacement_zone" => "40% (5% + 35%)",
      "maximum_possible" => "70% (5% + 35% + 10% + 10% + 10%)"
    },
    "limites" => {
      "montant_max_vehicule" => "16.000€ (y compris borne)",
      "montant_max_annuel_total" => "48.000€",
      "vehicules_max_annuel" => "3 véhicules électriques/retrofit",
      "bornes_max_annuel" => "3 bornes de recharge",
      "facture_minimum" => "500€"
    }
  }

  aide.delais_procedures = {
    "demande" => "Dans les 6 mois de la facture achat/transformation véhicule",
    "borne_recharge" => "Factures borne max 3 mois avant facture véhicule",
    "decision_administration" => "4 mois après demande complète",
    "envoi_justificatifs" => "15 mois après notification de décision d'octroi",
    "paiement" => "En une fois après contrôle justificatifs"
  }

  aide.url_officielle = "https://economie-emploi.brussels/prime-mobilite-utilitaire-retrofit"
  aide.statut = "active"
end

puts "✅ Aides Transition économique & Mobilité créées avec succès"
