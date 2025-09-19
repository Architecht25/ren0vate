# =====================================================
# AIDES BRUXELLES ENTREPRISES - EXPERTISES OU SERVICES EXTERNES
# =====================================================
# 2 aides: prime_consultance, prime_digitalisation
# =====================================================

puts "🧠 Création des aides Expertises & Services externes..."

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

  aide.delais_procedures = {
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

  aide.url_officielle = "https://economie-emploi.brussels/prime-consultance"
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

  aide.delais_procedures = {
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

  aide.url_officielle = "https://economie-emploi.brussels/prime-digitalisation"
  aide.statut = "active"
end

puts "✅ Aides Expertises & Services externes créées avec succès"
