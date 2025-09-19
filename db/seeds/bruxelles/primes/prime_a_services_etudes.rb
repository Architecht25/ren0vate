# =====================================================
# PRIME A : Services et études préalables
# =====================================================

puts "🏗️  Création des primes A - Services et études préalables..."

Prime.find_or_initialize_by(slug: "bruxelles_audit_energetique_maison").update!(
  titre: "A1 - Audit énergétique (maison unifamiliale) - Bruxelles",
  ordre_affichage: 1,
  icon_name: "clipboard-data",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 400, "condition": "Audit énergétique maison individuelle"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 400, "condition": "Audit énergétique maison individuelle"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 400, "condition": "Audit énergétique maison individuelle"}
  }'),
  condition: "Audit énergétique pour maison unifamiliale. Bâtiment construit au moins 10 ans avant la demande. Réalisé par auditeur agréé Bruxelles Environnement ou ingénieur/architecte avec expertise reconnue, indépendant des entreprises de travaux. Basé sur consommations réelles des 3 dernières années. Respect du cahier des charges minimal.",
  conseil: "État des lieux pour détecter points faibles et forts du bâtiment. Aide à prioriser les travaux d'amélioration et découvrir le gain réel. Montant fixe 400€ pour maison unifamiliale, sans conditions de revenus. Cumulable avec toutes les Primes RENOLUTION et autres aides (dans limite de 100% des travaux).",
  document: "Attestation entrepreneur (informations générales) + copie audit énergétique conforme au cahier des charges + factures détaillées au nom du demandeur (adresse chantier, description précise, prix unitaire HT, TVA, date) + preuves paiement (extraits bancaires si ≥3000€, ou facture acquittée si <3000€)",
  specifique: "Bruxelles - RENOLUTION A1 - Services et études préalables",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - 1 ou 0",
    "bruxelles_cat2": "Forfaitaire - 1 ou 0",
    "bruxelles_cat3": "Forfaitaire - 1 ou 0"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/audit_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_audit_energetique_batiment").update!(
  titre: "A1 - Audit énergétique (bâtiment complet) - Bruxelles",
  ordre_affichage: 2,
  icon_name: "building-check",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 3000, "condition": "Audit énergétique bâtiment complet"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 3000, "condition": "Audit énergétique bâtiment complet"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 3000, "condition": "Audit énergétique bâtiment complet"}
  }'),
  condition: "Audit énergétique pour bâtiment dans son entièreté (immeuble à appartements ou bâtiment non résidentiel). Bâtiment construit au moins 10 ans avant la demande. Réalisé par auditeur agréé Bruxelles Environnement ou ingénieur/architecte avec expertise reconnue, indépendant des entreprises de travaux. Basé sur consommations réelles des 3 dernières années. Respect du cahier des charges minimal.",
  conseil: "État des lieux complet pour immeubles collectifs et bâtiments non résidentiels. Montant fixe 3000€ par bâtiment, sans conditions de revenus. Postes éligibles: prestations chargé d'études, mesures consommations énergétiques. Prime couvre max 90% du montant facturé. Cumulable avec autres Primes RENOLUTION et aides (limite 100% travaux).",
  document: "Attestation entrepreneur (informations générales) + copie audit énergétique conforme au cahier des charges + factures détaillées au nom du demandeur (adresse chantier, description précise, prix unitaire HT, TVA, date) + preuves paiement (extraits bancaires si ≥3000€, ou facture acquittée si <3000€)",
  specifique: "Bruxelles - RENOLUTION A1 - Services et études préalables",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfaitaire - 1 ou 0",
    "bruxelles_cat2": "Forfaitaire - 1 ou 0",
    "bruxelles_cat3": "Forfaitaire - 1 ou 0"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/audit_batiment_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_etude_acoustique").update!(
  titre: "A2 - Étude acoustique - Bruxelles",
  ordre_affichage: 3,
  icon_name: "volume-2",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "pourcentage", "pourcentage": 2, "montant_max": 500, "condition": "2% des primes F6-H2 ou travaux isolation acoustique (selon montant le plus élevé)"},
    "bruxelles_cat2": {"type": "pourcentage", "pourcentage": 2, "montant_max": 1000, "condition": "2% des primes F6-H2 ou travaux isolation acoustique (selon montant le plus élevé)"},
    "bruxelles_cat3": {"type": "pourcentage", "pourcentage": 2, "montant_max": 1500, "condition": "2% des primes F6-H2 ou travaux isolation acoustique (selon montant le plus élevé)"}
  }'),
  condition: "Propriétaires occupants ou non-occupants de logements collectifs en copropriété ou AIS selon AGW. Obligatoire en complément des travaux d'isolation F6-H2. Bureau d'études agréé par Bruxelles Environnement avec section Acoustique. Avant travaux impactant l'acoustique du bâtiment.",
  conseil: "Prime A2 = 2% du montant le plus élevé entre primes F6-H2 octroyées ou coût travaux isolation acoustique. Délai traitement 90 jours max. Demande via formulaire en ligne ou courrier. Documents : rapport d'étude acoustique détaillé + facture bureau agréé + justificatifs propriété/copropriété/AIS.",
  document: "Rapport d'étude acoustique complet par bureau agréé Bruxelles Environnement (section Acoustique) + facture détaillée + justificatifs statut propriétaire/copropriété/AIS + preuve réalisation/projet travaux F6-H2",
  specifique: "Bruxelles - Renolution A2 - Études acoustiques obligatoires pour travaux d'isolation en logements collectifs",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant primes F6-H2 ou coût travaux isolation acoustique",
    "bruxelles_cat2": "Montant primes F6-H2 ou coût travaux isolation acoustique",
    "bruxelles_cat3": "Montant primes F6-H2 ou coût travaux isolation acoustique"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/etude_acoustique_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_etude_totem").update!(
  titre: "A3 - Étude matériaux de construction (TOTEM) - Bruxelles",
  ordre_affichage: 4,
  icon_name: "activity",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 200, "condition": "200€ par unité de logement - Sans condition de revenus"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 200, "condition": "200€ par unité de logement - Sans condition de revenus"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 200, "condition": "200€ par unité de logement - Sans condition de revenus"}
  }'),
  condition: "Tous publics (particuliers et professionnels). Bâtiments résidentiels construits au moins 10 ans avant demande. Étude TOTEM réalisée par architecte ou expert chargé de l\'étude. Mission indépendante de la conception habituelle. Respect du cahier des charges minimal TOTEM. Facture adressée au demandeur.",
  conseil: "TOTEM évalue l\'impact environnemental du bâtiment sur son cycle de vie. Prime fixe 200€ par unité de logement, sans condition de revenus. Minimum 250€ par adresse. Délai traitement 90 jours max. Demande via IRISbox après travaux (max 12 mois après facture de solde). Cumulable avec toutes autres primes RENOLUTION.",
  document: "Rapport d\'étude TOTEM conforme au cahier des charges minimal + factures détaillées libellées au nom du demandeur + preuves de paiement + attestation entrepreneur. Documents complémentaires si cumul avec autres primes RENOLUTION (titre propriété, extrait cadastral, etc.).",
  specifique: "Bruxelles - Renolution A3 - Évaluation impact environnemental matériaux via outil TOTEM belge",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre d\'unités de logement concernées",
    "bruxelles_cat2": "Nombre d\'unités de logement concernées",
    "bruxelles_cat3": "Nombre d\'unités de logement concernées"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/etude_totem.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# Suivi professionnel - 3 types distincts

Prime.find_or_initialize_by(slug: "bruxelles_suivi_architecte").update!(
  titre: "A4 - Suivi architecte - Bruxelles",
  ordre_affichage: 5,
  icon_name: "briefcase",
  unite: "%",
  type_de_valeur: "pourcentage",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 8,
      "condition": "8% du montant des primes octroyées pour mission d\'architecte inscrit à l\'Ordre"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 8,
      "condition": "8% du montant des primes octroyées pour mission d\'architecte inscrit à l\'Ordre"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 8,
      "condition": "8% du montant des primes octroyées pour mission d\'architecte inscrit à l\'Ordre"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), copropriétés forcées, AIS, syndics. Bâtiments résidentiels construits au moins 10 ans avant demande. Mission d\'architecte inscrit à l\'Ordre via convention écrite précisant travaux. Travaux par entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime A4 = 8% du montant des primes octroyées. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse. Délai traitement 90 jours max. Demande via IRISbox après travaux (max 12 mois après facture solde). Cumulable avec autres primes RENOLUTION.",
  document: "Convention écrite avec architecte + attestation entrepreneur + factures détaillées libellées au nom du demandeur + preuves de paiement + documents complémentaires (titre propriété, extrait cadastral, etc.) selon statut.",
  specifique: "Bruxelles - Renolution A4 - Suivi professionnel des travaux de rénovation par architecte",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant des primes RENOLUTION octroyées (€)",
    "bruxelles_cat2": "Montant des primes RENOLUTION octroyées (€)",
    "bruxelles_cat3": "Montant des primes RENOLUTION octroyées (€)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/suivi_architecte.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_suivi_ingenieur_stabilite").update!(
  titre: "A4 - Suivi ingénieur stabilité - Bruxelles",
  ordre_affichage: 6,
  icon_name: "calculator",
  unite: "%",
  type_de_valeur: "pourcentage",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "2% du montant des primes octroyées pour mission d\'ingénieur stabilité"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "2% du montant des primes octroyées pour mission d\'ingénieur stabilité"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "2% du montant des primes octroyées pour mission d\'ingénieur stabilité"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), copropriétés forcées, AIS, syndics. Bâtiments résidentiels construits au moins 10 ans avant demande. Mission d\'ingénieur stabilité via convention écrite précisant travaux. Travaux par entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime A4 = 2% du montant des primes octroyées. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse. Délai traitement 90 jours max. Demande via IRISbox après travaux (max 12 mois après facture solde). Cumulable avec autres primes RENOLUTION.",
  document: "Convention écrite avec ingénieur + attestation entrepreneur + factures détaillées libellées au nom du demandeur + preuves de paiement + documents complémentaires (titre propriété, extrait cadastral, etc.) selon statut.",
  specifique: "Bruxelles - Renolution A4 - Suivi professionnel des travaux de stabilité par ingénieur",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant des primes RENOLUTION octroyées (€)",
    "bruxelles_cat2": "Montant des primes RENOLUTION octroyées (€)",
    "bruxelles_cat3": "Montant des primes RENOLUTION octroyées (€)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/suivi_ingenieur.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_suivi_expert_facade").update!(
  titre: "A4 - Suivi expert façade - Bruxelles",
  ordre_affichage: 7,
  icon_name: "home-building",
  unite: "%",
  type_de_valeur: "pourcentage",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "2% du montant des primes octroyées pour étude façade expert"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "2% du montant des primes octroyées pour étude façade expert"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 2,
      "condition": "2% du montant des primes octroyées pour étude façade expert"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), copropriétés forcées, AIS, syndics. Bâtiments résidentiels construits au moins 10 ans avant demande. Étude façade par expert pour nettoyage/entretien définissant techniques adaptées sans dégradation matériaux. Travaux par entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime A4 = 2% du montant des primes octroyées. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse. Délai traitement 90 jours max. Demande via IRISbox après travaux (max 12 mois après facture solde). Cumulable avec autres primes RENOLUTION.",
  document: "Convention écrite avec expert façade + attestation entrepreneur + factures détaillées libellées au nom du demandeur + preuves de paiement + documents complémentaires (titre propriété, extrait cadastral, etc.) selon statut.",
  specifique: "Bruxelles - Renolution A4 - Suivi professionnel étude façade nettoyage/entretien",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant des primes RENOLUTION octroyées (€)",
    "bruxelles_cat2": "Montant des primes RENOLUTION octroyées (€)",
    "bruxelles_cat3": "Montant des primes RENOLUTION octroyées (€)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/suivi_facade.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_certificat_peb").update!(
  titre: "A5 - Certificat PEB - Bruxelles",
  ordre_affichage: 8,
  icon_name: "certificate",
  unite: "€",
  type_de_valeur: "montant_fixe",
  eligible_categories: ["bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat3": {
      "type": "montant_fixe",
      "montant": 150,
      "condition": "150€ par unité de logement - Uniquement catégorie III (ménages à faibles revenus)"
    }
  }'),
  condition: "Propriétaires occupants uniquement, catégorie III (ménages à faibles revenus). Unités de logement (maisons unifamiliales ou appartements) construites au moins 10 ans avant demande. Certificat PEB par certificateur PEB résidentiel agréé. Cumul obligatoire avec autre prime RENOLUTION pour atteindre minimum 250€.",
  conseil: "Prime A5 = 150€ par unité de logement pour ménages catégorie III uniquement. Obligatoirement cumuler avec autre prime RENOLUTION pour atteindre minimum 250€ par adresse. Délai traitement 90 jours max. Demande via IRISbox après réalisation certificat (max 12 mois après facture solde). Encourage anticipation obligation future PEB pour tous logements.",
  document: "Certificat PEB complet + attestation entrepreneur + factures détaillées du certificateur agréé (nom, n° agrément, n° TVA) + preuves de paiement + documents complémentaires si cumul avec autres primes RENOLUTION (titre propriété, extrait cadastral, etc.).",
  specifique: "Bruxelles - Renolution A5 - Soutien ménages faibles revenus anticipation obligation PEB",
  placeholder: JSON.parse('{
    "bruxelles_cat3": "Nombre d\'unités de logement à certifier (150€/unité)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/certificat_peb.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat3", region: "bruxelles")&.id
)

puts "✅ Primes A (Services et études) créées avec succès"
