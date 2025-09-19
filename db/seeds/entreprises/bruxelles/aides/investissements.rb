# =====================================================
# AIDES BRUXELLES ENTREPRISES - INVESTISSEMENTS
# =====================================================
# 5 aides: prime_materiel_travaux, prime_immobilier, prime_conformite_normes,
#          prime_securisation, prime_accessibilite
# =====================================================

puts "🏗️ Création des aides Investissements..."

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

  aide.delais_procedures = {
    "fiscalite" => "Cette prime fait partie des revenus imposables",
    "obligations_post_octroi" => "Respect des obligations après obtention",
    "zone_developpement" => "Vérifier si lieu investissement en zone développement",
    "materiel_roulant" => "Conditions spécifiques pour achat matériel roulant"
  }

  aide.url_officielle = "https://economie-emploi.brussels/prime-materiel-travaux"
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

  aide.delais_procedures = {
    "fiscalite" => "Cette prime fait partie des revenus imposables",
    "obligations_post_octroi" => "Respect des obligations après obtention",
    "zone_developpement" => "Zone proximité canal - vérifier localisation",
    "engagement_duree" => "15 ans (vs 5 ans matériel/travaux)",
    "minimum_investissement" => "100.000€ HTVA (vs 5k€-50k€ matériel)",
    "plafonds_reduits" => "Plafonds inférieurs vs prime matériel/travaux"
  }

  aide.url_officielle = "https://economie-emploi.brussels/prime-immobilier"
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

  aide.delais_procedures = {
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

  aide.url_officielle = "https://economie-emploi.brussels/prime-conformite-normes"
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

  aide.delais_procedures = {
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

  aide.url_officielle = "https://economie-emploi.brussels/prime-securisation"
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

  aide.delais_procedures = {
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

  aide.url_officielle = "https://economie-emploi.brussels/prime-accessibilite"
  aide.statut = "active"
end

puts "✅ Aides Investissements créées avec succès"
