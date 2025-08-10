# Aides aux entreprises Bruxelles - Seeds structurées
# Source officielle: economie-emploi.brussels

puts "🏢 Création des aides aux entreprises Bruxelles..."

# Mode sécurisé : ne supprime que si pas en production
if Rails.env.development? || ENV['FORCE_AIDE_RESET'] == 'true'
  puts "🗑️  Nettoyage des aides entreprises Bruxelles existantes (#{Rails.env})..."
  EntrepriseAide.where(region: "bruxelles").delete_all
else
  puts "🔒 Mode production : conservation des aides existantes"
end

# =============================================================================
# CATÉGORIE: TRANSITION ÉCONOMIQUE
# =============================================================================

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
      "montant_max_annuel_total" => "12.000€",
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


# =============================================================================
# CATÉGORIE: INVESTISSEMENTS
# =============================================================================

# Prime Matériel ou Travaux
EntrepriseAide.find_or_create_by(slug: "bruxelles_prime_materiel_travaux") do |aide|
  aide.titre = "Prime Matériel ou Travaux"
  aide.region = "bruxelles"
  aide.categorie = "investissements"
  aide.description = "Prime pour investissements matériels ou travaux visant la création, extension, diversification ou changement fondamental du processus de production d'un établissement"

  aide.secteurs_eligibles = [
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
    "Secteurs d'activités éligibles selon codes NACE-BEL 2025",
    "Exclusions selon arrêté - voir tableau conversion NACE-BEL 2008 vers 2025"
  ]

  aide.tailles_eligibles = ["tpe", "pme", "moyenne"] # TPE, PME et entreprises moyennes

  aide.montant_min = 5000   # Starter < 4 ans
  aide.montant_max = 500000 # En zone de développement
  aide.taux_aide = 5.0      # Taux de base micro/petites entreprises

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Engagement maintien activité 5 ans (4 ans crédit-bail)",
      "Engagement Actiris si aide > 20.000€ HTVA",
      "Pas en difficulté ni en procédure de recouvrement"
    ],
    "investissements" => [
      "Création d'établissement (< 4 ans après inscription BCE)",
      "Extension d'établissement existant",
      "Diversification vers nouveaux produits",
      "Changement fondamental processus production",
      "Biens supplémentaires (pas remplacement/modernisation)",
      "Propriété de l'entreprise (location non admise sauf accessoire)",
      "Exploitation en Région Bruxelles-Capitale",
      "Conformes législation urbanisme/environnement",
      "Inscrits en immobilisations corporelles"
    ],
    "montants" => [
      "Starter < 4 ans: minimum 5.000€ HTVA",
      "Micro > 4 ans: minimum 7.500€ HTVA",
      "Petite > 4 ans: minimum 15.000€ HTVA",
      "Moyenne > 4 ans: minimum 50.000€ HTVA",
      "Chaque facture ≥ 500€ HTVA",
      "Intervention minimum: 1.000€ HTVA"
    ]
  }

  aide.documents_requis = {
    "autorisation_prealable" => [
      "Demande via MonBEE avant début investissement",
      "Formulaire autorisation préalable",
      "Justificatifs éligibilité entreprise"
    ],
    "demande_definitive" => [
      "Formulaire définitif via MonBEE",
      "Toutes factures acquittées",
      "Preuves réalisation programme",
      "Dans les 12 mois après avis réception autorisation"
    ],
    "versement" => [
      "Déclaration de créance complétée",
      "Notification décision d'octroi"
    ]
  }

  aide.modalites_paiement = {
    "taux_base" => {
      "micro_petite" => "5% des investissements admis",
      "moyenne" => "2,5% des investissements admis"
    },
    "plafonds" => {
      "hors_zone_dev_micro_petite" => "20% maximum",
      "hors_zone_dev_moyenne" => "10% maximum",
      "zone_dev_micro_petite" => "30% maximum",
      "zone_dev_moyenne" => "15% maximum",
      "montant_max_hors_zone" => "350.000€ HTVA/an",
      "montant_max_zone_dev" => "500.000€ HTVA/an"
    },
    "majorations" => {
      "starter_micro_petite" => "+10%",
      "starter_moyenne" => "+2,5%",
      "exemplaire_environnemental_micro_petite" => "+10%",
      "exemplaire_environnemental_moyenne" => "+5%",
      "exemplaire_social_micro_petite" => "+10%",
      "exemplaire_social_moyenne" => "+5%",
      "zone_developpement_micro_petite" => "+5%",
      "zone_developpement_moyenne" => "+2,5%",
      "chantier_micro_petite" => "+10%",
      "chantier_moyenne" => "+5%"
    },
    "delais" => {
      "autorisation_prealable" => "Avant début investissement",
      "decision_autorisation" => "1 mois maximum",
      "demande_definitive" => "12 mois après avis réception",
      "decision_finale" => "4 mois après dossier complet",
      "paiement" => "Une fois après déclaration créance"
    }
  }

  aide.infos_complementaires = {
    "fiscalite" => "Cette prime fait partie des revenus imposables",
    "obligations_post_octroi" => "Respect des obligations après obtention",
    "zone_developpement" => "Vérifier si lieu investissement en zone développement",
    "materiel_roulant" => "Conditions spécifiques pour achat matériel roulant"
  }

  aide.statut = "active"
end

# Prime Immobilier
EntrepriseAide.find_or_create_by(slug: "bruxelles_prime_immobilier") do |aide|
  aide.titre = "Prime Immobilier"
  aide.region = "bruxelles"
  aide.categorie = "investissements"
  aide.description = "Prime pour investissements immobiliers (terrain ou bâtiment) visant la création ou l'extension d'un établissement"

  aide.secteurs_eligibles = [
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
    "Secteurs d'activités éligibles selon codes NACE-BEL 2025",
    "Exclusions selon arrêté - voir tableau conversion NACE-BEL 2008 vers 2025"
  ]

  aide.tailles_eligibles = ["tpe", "pme", "moyenne"] # TPE, PME et entreprises moyennes

  aide.montant_min = 100000  # Minimum obligatoire 100k€ HTVA
  aide.montant_max = 500000  # En zone de développement
  aide.taux_aide = 5.0       # Taux de base micro/petites entreprises

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Engagement maintien activité 15 ans (spécifique immobilier)",
      "Engagement Actiris si aide > 20.000€ HTVA",
      "Pas en difficulté ni en procédure de recouvrement"
    ],
    "investissements" => [
      "Création d'établissement (déménagement ou établissement supplémentaire)",
      "Extension d'établissement (achat immeuble précédemment loué)",
      "Nécessaires par rapport aux activités",
      "Gestion en personne prudente (pas somptuaire)",
      "Conformes législation urbanisme/environnement",
      "Propriété de l'entreprise (location non admise sauf accessoire)",
      "Repris en immobilisations corporelles (crédit-bail)",
      "Inscrits en immobilisations aux comptes",
      "Partie professionnelle en cas usage mixte"
    ],
    "montants" => [
      "Programme minimum: 100.000€ HTVA",
      "Intervention minimum: 1.000€ HTVA"
    ]
  }

  aide.documents_requis = {
    "autorisation_prealable" => [
      "Demande via MonBEE avant signature acte achat",
      "Extrait de compte/RIB en annexe",
      "Formulaire autorisation préalable"
    ],
    "demande_definitive" => [
      "Formulaire définitif via MonBEE",
      "Acte d'achat signé et payé",
      "Preuves réalisation programme",
      "Dans les 12 mois après avis réception autorisation"
    ],
    "versement" => [
      "Déclaration de créance complétée",
      "Notification décision d'octroi"
    ]
  }

  aide.modalites_paiement = {
    "taux_base" => {
      "micro_petite" => "5% des investissements admis",
      "moyenne" => "2,5% des investissements admis"
    },
    "plafonds" => {
      "hors_zone_dev_micro_petite" => "10% maximum (vs 20% matériel)",
      "hors_zone_dev_moyenne" => "5% maximum (vs 10% matériel)",
      "zone_dev_micro_petite" => "20% maximum (vs 30% matériel)",
      "zone_dev_moyenne" => "10% maximum (vs 15% matériel)",
      "montant_max_hors_zone" => "350.000€ HTVA/an (commun matériel+immobilier)",
      "montant_max_zone_dev" => "500.000€ HTVA/an (commun matériel+immobilier)"
    },
    "majorations" => {
      "starter_micro_petite" => "+5% (vs +10% matériel)",
      "starter_moyenne" => "+2,5%",
      "exemplaire_environnemental_micro_petite" => "+5% (vs +10% matériel)",
      "exemplaire_environnemental_moyenne" => "+2,5% (vs +5% matériel)",
      "exemplaire_social_micro_petite" => "+5% (vs +10% matériel)",
      "exemplaire_social_moyenne" => "+2,5% (vs +5% matériel)",
      "zone_developpement" => "+2,5% (toutes tailles)"
    },
    "delais" => {
      "autorisation_prealable" => "Avant signature acte achat",
      "decision_autorisation" => "1 mois maximum",
      "demande_definitive" => "12 mois après avis réception",
      "decision_finale" => "4 mois après dossier complet",
      "paiement" => "Une fois après déclaration créance"
    }
  }

  aide.infos_complementaires = {
    "fiscalite" => "Cette prime fait partie des revenus imposables",
    "obligations_post_octroi" => "Respect des obligations après obtention",
    "zone_developpement" => "Zone proximité canal - vérifier localisation",
    "engagement_duree" => "15 ans (vs 5 ans matériel/travaux)",
    "minimum_investissement" => "100.000€ HTVA (vs 5k€-50k€ matériel)",
    "plafonds_reduits" => "Plafonds inférieurs vs prime matériel/travaux"
  }

  aide.statut = "active"
end

# Prime Conformité aux normes
EntrepriseAide.find_or_create_by(slug: "bruxelles_prime_conformite_normes") do |aide|
  aide.titre = "Prime Conformité aux normes"
  aide.region = "bruxelles"
  aide.categorie = "investissements"
  aide.description = "Prime pour investissements de mise en conformité aux normes environnementales, de qualité, de sécurité ou d'hygiène"

  aide.secteurs_eligibles = [
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
    "Secteurs d'activités éligibles selon codes NACE-BEL 2025",
    "Entreprises nécessitant mise en conformité normes (ex: HACCP AFSCA)"
  ]

  aide.tailles_eligibles = ["tpe", "pme", "moyenne"] # TPE, PME et entreprises moyennes

  aide.montant_min = 5000   # Minimum 5k€ (vs 100k€ immobilier)
  aide.montant_max = 40000  # Maximum 40k€ fixe (vs 500k€ autres)
  aide.taux_aide = 40.0     # Taux fixe 40% (vs 5% base autres)

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Demande AVANT début investissement (vs autorisation préalable immobilier)",
      "Minimum 2 ans après création/changement unité établissement"
    ],
    "investissements" => [
      "Achat machine ou équipement",
      "Aménagement établissement",
      "Objectif: conformité normes environnementales/qualité/sécurité/hygiène",
      "Exemples: adaptation normes HACCP (AFSCA), autres normes sectorielles",
      "Rapport d'expert OBLIGATOIRE avant demande",
      "Nécessaires pour exercice activités",
      "Gestion personne prudente (pas somptuaire)",
      "Biens neufs (occasion admise si professionnel + garantie 6 mois)",
      "Propriété entreprise (location non admise sauf accessoire)",
      "Exploités en Région Bruxelles-Capitale",
      "Conformes législation urbanisme/environnement",
      "Inscrits en immobilisations"
    ],
    "exclusions" => [
      "Aéronefs",
      "Cycles et véhicules transport marchandises/personnes",
      "Biens appartenant actionnaire/groupe acquéreur",
      "Investissements exportation pays tiers"
    ],
    "montants" => [
      "Investissement minimum: 5.000€",
      "Facture minimum: 500€ HTVA",
      "Réalisation dans 12 mois maximum"
    ]
  }

  aide.documents_requis = {
    "prealable" => [
      "Rapport d'expert identifiant investissements nécessaires",
      "Expert indépendant spécialisé (2 ans expérience/5 ans)",
      "Compétence notoire avec références",
      "Intégrité dans fonction expert"
    ],
    "demande" => [
      "Demande via MonBEE après rapport expert",
      "Annexes selon plateforme",
      "Avis réception confirmant introduction"
    ],
    "justificatifs" => [
      "Pièces justificatives dans 12 mois notification",
      "Preuves réalisation et paiement",
      "Déclaration créance après validation"
    ]
  }

  aide.modalites_paiement = {
    "taux" => "40% des frais admis (taux fixe unique)",
    "plafond" => "40.000€ par bénéficiaire par année civile",
    "frequence" => "Maximum 1 prime par unité établissement tous les 4 ans",
    "delais" => {
      "demande_apres_rapport" => "Après obtention rapport expert",
      "debut_investissement" => "Lendemain introduction demande",
      "decision" => "4 mois maximum après dossier complet",
      "realisation" => "12 mois maximum pour investissements",
      "justificatifs" => "12 mois après notification octroi",
      "paiement" => "Une fois après déclaration créance"
    },
    "gestion_incomplete" => {
      "notification" => "15 jours si dossier incomplet",
      "complement" => "1 mois pour documents manquants"
    }
  }

  aide.infos_complementaires = {
    "fiscalite" => "Cette prime fait partie des revenus imposables",
    "obligations_post_octroi" => "Respect des obligations après obtention",
    "expert_requis" => "Rapport expert OBLIGATOIRE avant toute demande",
    "frequence_limitee" => "1 seule prime par établissement tous les 4 ans",
    "taux_eleve" => "40% (plus élevé que matériel 15-30% et immobilier 5-20%)",
    "plafond_bas" => "40k€ maximum (vs 350-500k€ autres investissements)",
    "delai_creation" => "Minimum 2 ans après création établissement",
    "credit_bail" => "Dispositions spéciales crédit-bail applicables",
    "usage_mixte" => "Dispositions usage mixte immeuble applicables",
    "materiel_non_roulant" => "Conditions spéciales matériel non-roulant"
  }

  aide.statut = "active"
end

# Prime Sécurisation de l'entreprise
EntrepriseAide.find_or_create_by(slug: "bruxelles_prime_securisation") do |aide|
  aide.titre = "Prime Sécurisation de l'entreprise"
  aide.region = "bruxelles"
  aide.categorie = "investissements"
  aide.description = "Prime pour investissements en systèmes de sécurisation : alarme, protection mécanique, vidéosurveillance, protection incendie"

  aide.secteurs_eligibles = [
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
    "Secteurs d'activités éligibles selon codes NACE-BEL 2025",
    "Toutes entreprises nécessitant sécurisation établissement"
  ]

  aide.tailles_eligibles = ["tpe", "pme", "moyenne"] # TPE, PME et entreprises moyennes

  aide.montant_min = 2000   # Minimum 2k€ (plus bas que conformité 5k€)
  aide.montant_max = 10000  # Maximum 10k€ (vs 40k€ conformité)
  aide.taux_aide = 40.0     # Taux de base 40% (60% starters)

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Demande AVANT début investissement"
    ],
    "investissements_securisation" => [
      "Système d'alarme",
      "Système protection mécanique (volet, grille, grillage)",
      "Système vidéosurveillance",
      "Système protection incendie",
      "Montant minimum: 2.000€ par demande"
    ],
    "conditions_generales" => [
      "Nécessaires par rapport aux activités",
      "Gestion bon père de famille (pas somptuaire)",
      "Biens neufs ou occasion (professionnel + garantie 6 mois)",
      "Propriété entreprise (location non admise sauf accessoire)",
      "Exploités en Région Bruxelles-Capitale",
      "Conformes législation urbanisme/environnement",
      "Inscrits en immobilisations",
      "Réalisation maximum 12 mois après notification octroi"
    ],
    "montants" => [
      "Investissement minimum: 2.000€",
      "Facture minimum: 500€ HTVA",
      "Maximum 1 prime par établissement tous les 4 ans"
    ]
  }

  aide.documents_requis = {
    "demande" => [
      "Demande via MonBEE avec annexes",
      "Avis réception confirmant introduction",
      "Documentation systèmes sécurisation prévus"
    ],
    "justificatifs" => [
      "Pièces justificatives dans 12 mois notification",
      "Preuves installation et paiement systèmes",
      "Déclaration créance après validation"
    ]
  }

  aide.modalites_paiement = {
    "taux_base" => {
      "micro_4ans_plus" => "40% des frais admis",
      "petite_moyenne" => "40% des frais admis"
    },
    "majoration_starter" => {
      "description" => "Entreprise immatriculée BCE < 4 ans",
      "taux_majore" => "60% des frais admis (40% + 20% majoration)",
      "calcul" => "Taux base 40% + majoration starter 20% = 60%"
    },
    "plafonds" => {
      "maximum_annuel" => "10.000€ par année civile",
      "frequence" => "1 prime par unité établissement tous les 4 ans"
    },
    "delais" => {
      "debut_investissement" => "Lendemain introduction demande",
      "decision" => "4 mois maximum après dossier complet",
      "realisation" => "12 mois maximum après notification octroi",
      "justificatifs" => "12 mois après notification octroi",
      "paiement" => "Une fois après déclaration créance"
    },
    "gestion_incomplete" => {
      "notification" => "15 jours si dossier incomplet",
      "complement" => "1 mois pour documents manquants"
    }
  }

  aide.infos_complementaires = {
    "fiscalite" => "Cette prime fait partie des revenus imposables",
    "obligations_post_octroi" => "Respect des obligations après obtention",
    "specialisation_securite" => "Aide spécialisée systèmes sécurisation uniquement",
    "taux_variable_age" => "40% entreprises >4 ans, 60% starters <4 ans",
    "plafond_limite" => "10k€ maximum (plus bas que autres investissements)",
    "frequence_limitee" => "1 seule prime par établissement tous les 4 ans",
    "montant_accessible" => "Minimum 2k€ (plus accessible que autres)",
    "credit_bail" => "Dispositions spéciales crédit-bail applicables",
    "usage_mixte" => "Dispositions usage mixte immeuble applicables",
    "materiel_non_roulant" => "Conditions spéciales matériel non-roulant",
    "systemes_vises" => "Alarme, protection mécanique, vidéosurveillance, incendie"
  }

  aide.statut = "active"
end

# Prime Accessibilité
EntrepriseAide.find_or_create_by(slug: "bruxelles_prime_accessibilite") do |aide|
  aide.titre = "Prime Accessibilité"
  aide.region = "bruxelles"
  aide.categorie = "investissements"
  aide.description = "Prime pour investissements favorisant l'accès aux personnes à mobilité réduite, âgées ou à des poussettes dans les locaux commerciaux"

  aide.secteurs_eligibles = [
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
    "Secteurs d'activités éligibles selon codes NACE-BEL 2025",
    "Locaux commerciaux nécessitant amélioration accessibilité"
  ]

  aide.tailles_eligibles = ["tpe", "pme", "moyenne"] # TPE, PME et entreprises moyennes

  aide.montant_min = 1000   # Minimum 1k€ (plus bas de tous)
  aide.montant_max = 80000  # Maximum 80k€ en montant aide (vs plafonds autres)
  aide.taux_aide = 50.0     # Taux de base 50% (plus élevé)

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Demande AVANT début programme investissements"
    ],
    "investissements_accessibilite" => [
      "Dépenses machines, équipements, aménagements pour accès PMR",
      "Installation éléments facilitant accès",
      "Modification installations existantes",
      "Inclut installations sanitaires entreprise",
      "Ciblage: personnes mobilité réduite, âgées, poussettes enfants",
      "Locaux commerciaux principalement visés"
    ],
    "conditions_generales" => [
      "Gestion personne prudente (pas somptuaire)",
      "Biens neufs ou occasion (professionnel + garantie 6 mois)",
      "Propriété entreprise (location non admise sauf accessoire)",
      "Exploités en Région Bruxelles-Capitale",
      "Conformes législation urbanisme/environnement",
      "Inscrits en immobilisations corporelles",
      "Réalisation maximum 12 mois après notification octroi"
    ],
    "exclusions" => [
      "Biens appartenant actionnaire/groupe acquéreur",
      "Investissements exportation pays tiers"
    ],
    "montants" => [
      "Investissement minimum: 1.000€",
      "Facture minimum: 500€ HTVA",
      "Maximum 1 investissement par année civile"
    ]
  }

  aide.documents_requis = {
    "demande" => [
      "Demande via MonBEE avec annexes",
      "AVANT mise en œuvre programme",
      "Avis réception confirmant introduction"
    ],
    "justificatifs" => [
      "Pièces justificatives dans 15 mois notification (vs 12 mois autres)",
      "Preuves installation accessibilité",
      "Déclaration créance après validation"
    ]
  }

  aide.modalites_paiement = {
    "taux_base" => "50% des dépenses éligibles (taux le plus élevé)",
    "plafond_maximum" => "70% avec majorations (plafonné)",
    "montant_aide_max" => "80.000€ maximum (montant aide, pas investissement)",
    "majorations" => {
      "starter" => "+10% (entreprise immatriculée BCE < 4 ans)",
      "exemplaire_environnemental" => "+10%",
      "exemplaire_social" => "+10%",
      "cumul_possible" => "Maximum 70% si plusieurs critères (50% + 20%)"
    },
    "exemples_calcul" => {
      "entreprise_standard" => "50% taux de base",
      "starter_seul" => "60% (50% + 10% starter)",
      "exemplaire_env_social" => "70% (50% + 10% + 10%, maximum plafonné)"
    },
    "frequence" => "Maximum 1 investissement subsidié par année civile",
    "delais" => {
      "decision" => "4 mois maximum après dossier complet",
      "realisation" => "12 mois maximum après notification octroi",
      "justificatifs" => "15 mois après notification (vs 12 mois autres)",
      "paiement" => "Une fois après déclaration créance"
    },
    "gestion_incomplete" => {
      "notification" => "15 jours si dossier incomplet",
      "complement" => "1 mois pour documents manquants"
    }
  }

  aide.infos_complementaires = {
    "fiscalite" => "Cette prime fait partie des revenus imposables",
    "obligations_post_octroi" => "Respect des obligations après obtention",
    "objectif_social" => "Amélioration accessibilité PMR, personnes âgées, poussettes",
    "taux_plus_eleve" => "50-70% (vs 40% autres, 5-30% matériel/immobilier)",
    "montant_aide_limite" => "80k€ en aide (pas en investissement)",
    "minimum_accessible" => "1k€ minimum (plus accessible)",
    "delai_justificatifs_long" => "15 mois pour justificatifs (vs 12 mois)",
    "frequence_annuelle" => "1 investissement/an (vs 4 ans sécurité/conformité)",
    "credit_bail" => "Dispositions spéciales crédit-bail applicables",
    "usage_mixte" => "Dispositions usage mixte immeuble applicables",
    "materiel_non_roulant" => "Conditions spéciales matériel non-roulant",
    "reglementation_minimis" => "Investissements soumis règlement de minimis"
  }

  aide.statut = "active"
end


# =============================================================================
# CATÉGORIE: RECRUTEMENT ET FORMATION
# =============================================================================

# Prime Formation
EntrepriseAide.find_or_create_by(slug: "bruxelles_prime_formation") do |aide|
  aide.titre = "Prime Formation"
  aide.region = "bruxelles"
  aide.categorie = "recrutement_formation"
  aide.description = "Prime pour formations du personnel et dirigeants dans le développement économique, transition économique, langues, management, gestion, marketing, technique et juridique"

  aide.secteurs_eligibles = [
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
    "Secteurs d'activités éligibles selon codes NACE-BEL 2025",
    "Entreprises ayant du personnel permanent et dirigeants"
  ]

  aide.tailles_eligibles = ["tpe", "pme", "moyenne"] # TPE, PME et entreprises moyennes

  aide.montant_min = 300    # Intervention minimum par demande
  aide.montant_max = 20000  # Maximum 20k€ par année civile
  aide.taux_aide = 40.0     # Taux de base 40% (jusqu'à 80% avec majorations)

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Demande au plus tard veille début formation"
    ],
    "formations_eligibles" => [
      "Développement économique de l'entreprise",
      "Amélioration du fonctionnement",
      "Transition économique (selon définition officielle)",
      "Langues, management, gestion d'entreprise",
      "Marketing, formation technique, domaine juridique",
      "Ciblage: membres du personnel et dirigeants"
    ],
    "exclusions_beneficiaires" => [
      "Intérimaires (non éligibles)",
      "Étudiants travail temporaire (non éligibles)"
    ],
    "exclusions_formations" => [
      "Formations portant sur investissement",
      "Formations pratiques médicales",
      "Formations obligatoires profession réglementée",
      "Conférences et séminaires",
      "Formations ne visant pas rôle actuel/futur dans entreprise",
      "Formations permis de conduire (toutes catégories)"
    ],
    "frais_eligibles" => [
      "Droits d'inscription",
      "Frais épreuves à l'entrée",
      "Frais épreuves certificatives",
      "Supports didactiques écrits ou audiovisuels",
      "Exclusion: logiciels"
    ],
    "duree" => "Maximum 6 mois consécutifs par formation"
  }

  aide.documents_requis = {
    "demande" => [
      "Demande via MonBEE veille début formation",
      "Annexes nécessaires selon plateforme",
      "Avis réception confirmant introduction",
      "Demande séparée pour chaque formation"
    ],
    "justificatifs" => [
      "Factures formations",
      "Preuves paiement par compte entreprise",
      "Attestation participation organisme formation",
      "Dans 12 mois après notification octroi"
    ]
  }

  aide.modalites_paiement = {
    "taux_base" => "40% des dépenses éligibles",
    "plafond_maximum" => "80% avec majorations (plafonné)",
    "montant_max_formation" => "5.000€ par formation en dépenses éligibles",
    "montant_max_annuel" => "20.000€ par année civile",
    "intervention_minimum" => "300€ par demande",
    "frequence" => "Maximum 10 formations subsidiées par année civile",
    "majorations" => {
      "starter_micro_petite" => "+20% (entreprise immatriculée BCE < 4 ans)",
      "starter_moyenne" => "+10%",
      "exemplaire_environnemental_micro_petite" => "+20%",
      "exemplaire_environnemental_moyenne" => "+10%",
      "exemplaire_social_micro_petite" => "+20%",
      "exemplaire_social_moyenne" => "+10%",
      "zone_developpement_micro_petite" => "+20%",
      "zone_developpement_moyenne" => "+10%"
    },
    "exemples_calcul" => {
      "entreprise_standard" => "40% taux de base",
      "micro_starter" => "60% (40% + 20% starter)",
      "petite_exemplaire_zone_dev" => "80% (40% + 20% + 20%, maximum)"
    },
    "delais" => {
      "demande" => "Au plus tard veille début formation",
      "decision" => "4 mois maximum après dossier complet",
      "debut_formation_min" => "Lendemain introduction demande",
      "debut_formation_max" => "3 mois après notification octroi",
      "justificatifs" => "12 mois après notification octroi",
      "paiement" => "Une fois après déclaration créance"
    },
    "gestion_incomplete" => {
      "notification" => "15 jours si dossier incomplet",
      "complement" => "1 mois pour documents manquants"
    }
  }

  aide.infos_complementaires = {
    "fiscalite" => "Cette prime fait partie des revenus imposables",
    "obligations_post_octroi" => "Respect des obligations après obtention",
    "profil_formateur" => {
      "specialisation" => "Spécialisé dans domaine concerné",
      "activite_principale" => "Formation parmi activités principales (NACE 85)",
      "experience" => "Exercice formation minimum 2 ans",
      "competence" => "Compétence étayée références et expérience",
      "independance" => "Indépendant de l'entreprise",
      "limite_formations" => "Maximum 5 formations subsidiées/entreprise sur 2 ans",
      "facturation" => "Envoi facture direct ou via service facturation",
      "exception" => "Particulier coopérative emploi exemption NACE"
    },
    "communications" => "Toutes communications via mail - surveiller spams",
    "gestion_multiple" => "Chaque formation = demande séparée",
    "domaines_vises" => "Développement économique, transition, langues, management, gestion, marketing, technique, juridique",
    "exclusions_strictes" => "Intérimaires, étudiants temporaires, formations investissement, médicales, obligatoires, conférences, permis"
  }

  aide.statut = "active"
end

# Prime Recrutement
EntrepriseAide.find_or_create_by(slug: "bruxelles_prime_recrutement") do |aide|
  aide.titre = "Prime Recrutement"
  aide.region = "bruxelles"
  aide.categorie = "recrutement_formation"
  aide.description = "Prime pour micro-entreprises recrutant un nouveau travailleur avec accroissement des effectifs et conditions de maintien"

  aide.secteurs_eligibles = [
    "MICRO-ENTREPRISES UNIQUEMENT avec siège d'exploitation en Région de Bruxelles-Capitale",
    "Secteurs d'activités éligibles selon codes NACE-BEL 2025",
    "Exclusion: entreprises > micro selon définition UE"
  ]

  aide.tailles_eligibles = ["tpe"] # UNIQUEMENT micro-entreprises (TPE restreint)

  aide.montant_min = 5000   # Base 5k€ (prorata temps travail)
  aide.montant_max = 15000  # Maximum avec toutes majorations
  aide.taux_aide = 100.0    # Montant forfaitaire (pas de pourcentage)

  aide.conditions_eligibilite = {
    "entreprise_micro" => [
      "MICRO-ENTREPRISE uniquement (critères UE stricte)",
      "Siège d'exploitation en Région de Bruxelles-Capitale",
      "Minimum 1 ETP CDI (hors intérimaires et recruté demandé)",
      "Accroissement effectifs vs 12 mois avant demande",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs"
    ],
    "travailleur_recrute" => [
      "Pas inscrit registre personnel 3 ans précédents (entreprise/liées)",
      "Majoritairement rattaché unité établissement Bruxelles",
      "Entrée en fonction: 3 mois avant à jour introduction demande",
      "Exception registre: étudiant, stagiaire, formation alternance FP Classes moyennes"
    ],
    "demande" => [
      "Introduction: entrée fonction à 3 mois après maximum",
      "Demande via MonBEE avec annexes"
    ],
    "maintien_emploi" => [
      "Maintien 12 mois minimum mi-temps pour 25% aide",
      "Maintien 24 mois + conditions CA/effectifs pour 25% final"
    ]
  }

  aide.documents_requis = {
    "demande" => [
      "Demande via MonBEE dans 3 mois entrée fonction",
      "Annexes nécessaires selon plateforme",
      "Avis réception confirmant introduction"
    ],
    "justificatifs_tranches" => [
      "Tranche 1 (50%): Avec décision octroi",
      "Tranche 2 (25%): Preuves 12 mois emploi mi-temps minimum",
      "Tranche 3 (25%): Preuves 24 mois + CA +50% + conditions",
      "Délai: 6 mois pour justificatifs après moments référence"
    ],
    "suivi_obligatoire" => [
      "Information départ travailleur dans 3 mois",
      "Possibilité remplacement dans 9 mois après notification départ"
    ]
  }

  aide.modalites_paiement = {
    "montant_base" => "5.000€ (prorata temps travail)",
    "calcul_prorata" => "Temps plein = 5k€, mi-temps = 2,5k€",
    "plafond_maximum" => "15.000€ avec toutes majorations",
    "frequence" => "Maximum 1 demande par 3 ans par bénéficiaire",
    "majorations_fixes" => {
      "starter" => "+5.000€ (entreprise < 4 ans BCE)",
      "exemplaire_environnemental" => "+5.000€",
      "exemplaire_social" => "+5.000€",
      "zone_developpement" => "+5.000€",
      "carte_activa" => "+5.000€ (travailleur recruté)",
      "formation_limitee" => "+5.000€ (pas diplôme > secondaire inférieur)"
    },
    "exemples_calcul" => {
      "base_seule" => "5.000€",
      "micro_starter_zone_activa" => "15.000€ (5k + 5k + 5k + 5k, plafonné)",
      "mi_temps_base" => "2.500€ (prorata)"
    },
    "paiement_echelonne" => {
      "tranche_1" => "50% avec décision octroi",
      "tranche_2" => "25% après 12 mois emploi (minimum mi-temps)",
      "tranche_3" => "25% après 24 mois + conditions strictes"
    },
    "conditions_tranche_3" => {
      "ca_augmentation" => "CA +50% (12 mois post vs 12 mois pré demande)",
      "maintien_emploi" => "Travailleur toujours présent minimum mi-temps",
      "maintien_effectifs" => "Pas réduction effectifs depuis octroi",
      "conditions_supplementaires" => "Au moins 1 ETP supplémentaire OU exemplaire social/environnemental"
    },
    "delais" => {
      "demande" => "Entrée fonction à 3 mois après maximum",
      "decision" => "4 mois maximum après dossier complet",
      "justificatifs" => "6 mois après moments référence",
      "rappel_admin" => "1 mois avant expiration si manquant"
    },
    "gestion_incomplete" => {
      "notification" => "15 jours si dossier incomplet",
      "complement" => "1 mois pour documents manquants"
    }
  }

  aide.infos_complementaires = {
    "fiscalite" => "Cette prime fait partie des revenus imposables",
    "obligations_post_octroi" => "Respect des obligations après obtention",
    "restriction_taille" => "UNIQUEMENT micro-entreprises (critères UE)",
    "paiement_echelonne" => "3 tranches: 50% + 25% + 25% selon conditions",
    "prorata_temps" => "Montants calculés selon temps travail effectif",
    "majorations_cumulables" => "6 majorations possibles de 5k€ chacune",
    "suivi_strict" => "Conditions maintien emploi et croissance CA",
    "flexibilite_remplacement" => "9 mois pour remplacer si départ travailleur",
    "accroissement_obligatoire" => "Effectifs doivent augmenter vs 12 mois avant",
    "rattachement_bruxelles" => "Travailleur majoritairement en unité bruxelloise",
    "exclusion_historique" => "Pas employé dans groupe 3 ans précédents",
    "delai_entre_aides" => "1 demande maximum tous les 3 ans",
    "criteres_ca_stricts" => "Croissance 50% CA obligatoire pour tranche finale"
  }

  aide.statut = "active"
end

# =============================================================================
# CATÉGORIE: EXPERTISES OU SERVICES EXTERNES
# =============================================================================

# Prime Consultance
EntrepriseAide.find_or_create_by(slug: "bruxelles_prime_consultance") do |aide|
  aide.titre = "Prime Consultance"
  aide.region = "bruxelles"
  aide.categorie = "expertises_services_externes"
  aide.description = "Prime pour missions de consultance externe ponctuelle dans l'analyse commerciale, stratégique, financière, juridique, technique, communication ou management"

  aide.secteurs_eligibles = [
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
    "Secteurs d'activités éligibles selon codes NACE-BEL 2025",
    "Entreprises nécessitant expertise externe ponctuelle"
  ]

  aide.tailles_eligibles = ["tpe", "pme", "moyenne"] # TPE, PME et entreprises moyennes

  aide.montant_min = 500    # Intervention minimum par mission
  aide.montant_max = 7500   # Maximum 7,5k€ par année civile
  aide.taux_aide = 25.0     # Taux de base 25% (jusqu'à 70% avec majorations)

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Demande AVANT début mission consultance"
    ],
    "missions_eligibles" => [
      "Analyse commerciale, stratégique ou financière (développer revenus)",
      "Étude juridique (exclusion contentieux)",
      "Étude technique",
      "Stratégie de communication",
      "Management et changement processus organisationnels",
      "Caractère exceptionnel résolvant problème ponctuel",
      "Compétences insuffisantes en interne"
    ],
    "exclusions_missions" => [
      "Sous-traitance permanente et régulière",
      "Tenue comptabilité entreprise",
      "Missions contentieux juridique",
      "Activités courantes/récurrentes"
    ],
    "duree_mission" => "Maximum 6 mois par mission",
    "frequence" => "Maximum 3 missions par an (consultance + transition économique cumulées)"
  }

  aide.documents_requis = {
    "demande" => [
      "Demande via MonBEE veille début mission",
      "Annexes selon plateforme",
      "Avis réception confirmant introduction"
    ],
    "justificatifs" => [
      "Pièces justificatives dans 12 mois notification",
      "Factures consultant et preuves paiement",
      "Rapport mission et livrables",
      "Déclaration créance après validation"
    ]
  }

  aide.modalites_paiement = {
    "taux_base" => "25% des dépenses éligibles",
    "plafond_maximum" => "70% avec majorations (plafonné)",
    "montant_max_annuel" => "7.500€ par année civile",
    "intervention_minimum" => "500€ par mission",
    "frequence_missions" => "Maximum 3 missions subsidiées/an (avec transition économique)",
    "majorations" => {
      "starter_micro_petite" => "+25% (entreprise immatriculée BCE < 4 ans)",
      "starter_moyenne" => "+20%",
      "exemplaire_environnemental_micro_petite" => "+30%",
      "exemplaire_environnemental_moyenne" => "+20%",
      "exemplaire_social_micro_petite" => "+30%",
      "exemplaire_social_moyenne" => "+20%"
    },
    "exemples_calcul" => {
      "entreprise_standard" => "25% taux de base",
      "micro_starter" => "50% (25% + 25% starter)",
      "petite_exemplaire_env_social" => "70% (25% + 30% + 30%, plafonné à 70%)"
    },
    "delais" => {
      "demande" => "Au plus tard veille début mission",
      "decision" => "4 mois maximum après dossier complet",
      "debut_mission_min" => "Lendemain introduction demande",
      "debut_mission_max" => "3 mois après notification octroi",
      "justificatifs" => "12 mois après notification octroi",
      "paiement" => "Une fois après déclaration créance"
    },
    "gestion_incomplete" => {
      "notification" => "15 jours si dossier incomplet",
      "complement" => "1 mois pour documents manquants"
    }
  }

  aide.infos_complementaires = {
    "fiscalite" => "Cette prime fait partie des revenus imposables",
    "obligations_post_octroi" => "Respect des obligations après obtention",
    "profil_consultant" => {
      "activite_principale" => "Prestation services conseil concernés comme activité principale",
      "specialisation" => "Spécialisé dans domaine concerné",
      "experience" => "Exercice consultance minimum 2 ans",
      "competence" => "Compétence étayée références et expérience pratique",
      "independance" => "Indépendant de l'entreprise",
      "limite_missions" => "Maximum 2 missions subsidiées pour entreprise sur 2 dernières années",
      "facturation" => "Envoi facture direct ou via service facturation",
      "exception" => "Personne physique coopérative emploi exemption activité principale"
    },
    "caractere_exceptionnel" => "Mission ponctuelle, pas sous-traitance régulière",
    "domaines_vises" => "Commercial, stratégique, financier, juridique, technique, communication, management",
    "cumul_limite" => "3 missions/an avec transition économique consultance",
    "taux_evolutif" => "25-70% selon profil (vs 40-80% formation)",
    "plafond_modere" => "7,5k€/an (vs 15-20k€ autres aides)",
    "duree_limitee" => "6 mois maximum par mission"
  }

  aide.statut = "active"
end

# Prime Digitalisation
EntrepriseAide.find_or_create_by(slug: "bruxelles_prime_digitalisation") do |aide|
  aide.titre = "Prime Digitalisation"
  aide.region = "bruxelles"
  aide.categorie = "expertises_services_externes"
  aide.description = "Prime pour missions de consultance en digitalisation des processus, sécurisation informatique et développement technique de sites internet"

  aide.secteurs_eligibles = [
    "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
    "Secteurs d'activités éligibles selon codes NACE-BEL 2025",
    "Entreprises s'engageant à respecter charte numérique responsable"
  ]

  aide.tailles_eligibles = ["tpe", "pme", "moyenne"] # TPE, PME et entreprises moyennes

  aide.montant_min = 500    # Intervention minimum par mission
  aide.montant_max = 10000  # Maximum 10k€ par année civile (vs 7,5k€ consultance)
  aide.taux_aide = 25.0     # Taux de base 25% (jusqu'à 70% avec majorations)

  aide.conditions_eligibilite = {
    "entreprise" => [
      "PME avec siège d'exploitation en Région de Bruxelles-Capitale",
      "Finalité économique et commerciale",
      "Maximum 75% de financement public",
      "Maximum 300.000€ d'aides de minimis sur 3 dernières années",
      "En ordre avec obligations de publication des comptes annuels",
      "Plan de diversité obligatoire si > 50 travailleurs",
      "Engagement respect charte numérique responsable (OBLIGATOIRE)",
      "Demande AVANT début mission consultance"
    ],
    "missions_digitalisation" => [
      "Digitalisation processus internes entreprise",
      "Digitalisation moyens de production",
      "Digitalisation produits ou services",
      "Sécurisation informatique entreprise",
      "Développement/amélioration technique site internet",
      "Caractère exceptionnel résolvant problème ponctuel",
      "Compétences insuffisantes en interne"
    ],
    "exclusions_missions" => [
      "Sous-traitance permanente et régulière",
      "Maintenance courante systèmes",
      "Activités récurrentes digitalisation",
      "Prestations non liées transformation numérique"
    ],
    "duree_mission" => "Maximum 6 mois par mission",
    "frequence" => "Maximum 2 missions subsidiées par année civile"
  }

  aide.documents_requis = {
    "demande" => [
      "Demande via MonBEE veille début mission",
      "Annexes selon plateforme",
      "Engagement signé charte numérique responsable",
      "Avis réception confirmant introduction"
    ],
    "justificatifs" => [
      "Pièces justificatives dans 12 mois notification",
      "Factures consultant et preuves paiement",
      "Rapport mission et livrables techniques",
      "Preuves respect charte numérique responsable",
      "Déclaration créance après validation"
    ]
  }

  aide.modalites_paiement = {
    "taux_base" => "25% des dépenses éligibles",
    "plafond_maximum" => "70% avec majorations ET 10.000€ maximum/an",
    "montant_max_annuel" => "10.000€ par année civile (vs 7.500€ consultance)",
    "intervention_minimum" => "500€ par mission",
    "frequence_missions" => "Maximum 2 missions subsidiées/an (vs 3 consultance)",
    "majorations" => {
      "starter_micro_petite" => "+25% (entreprise immatriculée BCE < 4 ans)",
      "starter_moyenne" => "+20%",
      "exemplaire_environnemental_micro_petite" => "+30%",
      "exemplaire_environnemental_moyenne" => "+20%",
      "exemplaire_social_micro_petite" => "+30%",
      "exemplaire_social_moyenne" => "+20%"
    },
    "exemples_calcul" => {
      "entreprise_standard" => "25% taux de base",
      "micro_starter" => "50% (25% + 25% starter)",
      "petite_exemplaire_env_social" => "70% (25% + 30% + 30%, plafonné à 70%)"
    },
    "double_plafond" => {
      "pourcentage" => "Maximum 70% des dépenses éligibles",
      "montant" => "Maximum 10.000€ par année civile"
    },
    "delais" => {
      "demande" => "Au plus tard veille début mission",
      "decision" => "4 mois maximum après dossier complet",
      "debut_mission_min" => "Lendemain introduction demande",
      "debut_mission_max" => "3 mois après notification octroi",
      "justificatifs" => "12 mois après notification octroi",
      "paiement" => "Une fois après déclaration créance"
    },
    "gestion_incomplete" => {
      "notification" => "15 jours si dossier incomplet",
      "complement" => "1 mois pour documents manquants"
    }
  }

  aide.infos_complementaires = {
    "fiscalite" => "Cette prime fait partie des revenus imposables",
    "obligations_post_octroi" => "Respect des obligations après obtention",
    "charte_numerique_responsable" => "Engagement obligatoire respect principes durabilité numérique",
    "profil_consultant" => {
      "activite_principale" => "Prestation services conseil digitalisation comme activité principale",
      "specialisation" => "Spécialisé dans domaine digitalisation concerné",
      "experience" => "Exercice consultance minimum 2 ans",
      "competence" => "Compétence étayée références et expérience pratique",
      "independance" => "Indépendant de l'entreprise",
      "facturation" => "Envoi facture direct ou via service facturation",
      "exception" => "Personne physique coopérative emploi exemption activité principale"
    },
    "caracteristiques_uniques" => {
      "focus_digital" => "Spécialisé transformation numérique vs consultance générale",
      "plafond_superieur" => "10k€/an vs 7,5k€ consultance classique",
      "frequence_reduite" => "2 missions/an vs 3 missions consultance",
      "charte_obligatoire" => "Engagement numérique responsable requis",
      "domaines_techniques" => "Processus, production, produits, sécurité, sites web"
    },
    "caractere_exceptionnel" => "Mission ponctuelle, pas sous-traitance régulière",
    "domaines_vises" => "Digitalisation processus/production/produits, sécurisation, sites web",
    "duree_limitee" => "6 mois maximum par mission",
    "responsabilite_numerique" => "Approche durable transformation digitale"
  }

  aide.statut = "active"
end

puts "✅ #{EntrepriseAide.where(region: 'bruxelles').count} aides aux entreprises Bruxelles créées"
