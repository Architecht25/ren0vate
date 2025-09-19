# =====================================================
# AIDES BRUXELLES ENTREPRISES - RECRUTEMENT ET FORMATION
# =====================================================
# 2 aides: prime_formation, prime_recrutement
# =====================================================

puts "👥 Création des aides Recrutement & Formation..."

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

  aide.delais_procedures = {
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

  aide.url_officielle = "https://economie-emploi.brussels/prime-formation"
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

  aide.delais_procedures = {
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

  aide.url_officielle = "https://economie-emploi.brussels/prime-recrutement"
  aide.statut = "active"
end

puts "✅ Aides Recrutement & Formation créées avec succès"
