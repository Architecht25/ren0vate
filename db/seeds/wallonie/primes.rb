puts "🏴󠁢󠁥󠁷󠁡󠁬󠁿 Création des primes Wallonie..."

# Nettoyage des primes Wallonie existantes
Prime.where(region: "wallonie").delete_all

# === AUDIT ===

Prime.find_or_initialize_by(slug: "wallonie_realisation_audit_logement").update!(
  titre: "Réalisation d'un audit logement - Wallonie",
  ordre_affichage: 1,
  icon_name: "search",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 840, "condition": "Audit énergétique complet"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 560, "condition": "Audit énergétique complet"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 420, "condition": "Audit énergétique complet"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 280, "condition": "Audit énergétique complet"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 76, "condition": "Audit énergétique complet"}
  }'),
  condition: "Réalisé par auditeur agréé. Rapport dans les 6 mois.",
  conseil: "Étape préalable recommandée avant travaux.",
  document: "Rapport d'audit + facture auditeur agréé",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/audit_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === TOITURE ===

Prime.find_or_initialize_by(slug: "wallonie_toiture_remplacement_couverture").update!(
  titre: "Toiture - Remplacement de la couverture - Wallonie",
  ordre_affichage: 2,
  icon_name: "hammer",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 24, "condition": "Remplacement complet"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 16, "condition": "Remplacement complet"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 12, "condition": "Remplacement complet"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 8, "condition": "Remplacement complet"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 4, "condition": "Remplacement complet"}
  }'),
  condition: "Remplacement complet de la couverture. Isolation intégrée recommandée.",
  conseil: "Coordonner avec isolation thermique. Prévoir évacuation gravats.",
  document: "Devis détaillé + factures + photos avant/après",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/remplacement_toiture_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_toiture_appropriation_charpente").update!(
  titre: "Toiture - Appropriation de la charpente - Wallonie",
  ordre_affichage: 3,
  icon_name: "tools",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 600, "condition": "Renforcement charpente"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 400, "condition": "Renforcement charpente"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 300, "condition": "Renforcement charpente"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 200, "condition": "Renforcement charpente"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 100, "condition": "Renforcement charpente"}
  }'),
  condition: "Renforcement ou appropriation de la charpente existante.",
  conseil: "Expertise structure recommandée avant travaux.",
  document: "Rapport expertise + factures + attestation conformité",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/charpente_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_toiture_evacuation_eaux_pluviales").update!(
  titre: "Toiture - Évacuation des eaux pluviales - Wallonie",
  ordre_affichage: 4,
  icon_name: "tint",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 240, "condition": "Remplacement système"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 160, "condition": "Remplacement système"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 120, "condition": "Remplacement système"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 50, "condition": "Remplacement système"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 40, "condition": "Remplacement système"}
  }'),
  condition: "Remplacement du dispositif de collecte et d'évacuation des eaux pluviales.",
  conseil: "Dimensionnement selon surface toiture. Raccordement aux égouts.",
  document: "Factures + plan évacuation + photos installation",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/gouttiere_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_toiture_isolation_thermique").update!(
  titre: "Toiture - Isolation thermique du toit ou des combles - Wallonie",
  ordre_affichage: 5,
  icon_name: "house",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 120, "condition": "R ≥ 4,5 m²K/W"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 80, "condition": "R ≥ 4,5 m²K/W"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 60, "condition": "R ≥ 4,5 m²K/W"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 40, "condition": "R ≥ 4,5 m²K/W"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 20, "condition": "R ≥ 4,5 m²K/W"}
  }'),
  condition: "Résistance thermique R ≥ 4,5 m²K/W. Matériaux certifiés.",
  conseil: "Vérifier continuité isolation et étanchéité air.",
  document: "Factures + certificats matériaux + attestation entrepreneur",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/isolation_toiture_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_toiture_isolation_biosource").update!(
  titre: "Toiture - Isolation thermique BIOSOURCÉE - Wallonie",
  ordre_affichage: 6,
  icon_name: "leaf",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 156, "condition": "R ≥ 4,5 + biosourcé"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 104, "condition": "R ≥ 4,5 + biosourcé"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 78, "condition": "R ≥ 4,5 + biosourcé"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 52, "condition": "R ≥ 4,5 + biosourcé"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 26, "condition": "R ≥ 4,5 + biosourcé"}
  }'),
  condition: "Matériau biosourcé certifié. R ≥ 4,5 m²K/W.",
  conseil: "Prime majorée pour matériaux écologiques. Certification obligatoire.",
  document: "Factures + certificat biosourcé + attestation performance",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/isolation_biosource_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)
# === MURS ===

Prime.find_or_initialize_by(slug: "wallonie_assechement_murs_infiltration").update!(
  titre: "Assèchement des murs - infiltration - Wallonie",
  ordre_affichage: 7,
  icon_name: "droplet",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 14.4, "condition": "Traitement infiltration"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 9.6, "condition": "Traitement infiltration"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 7.2, "condition": "Traitement infiltration"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 4.8, "condition": "Traitement infiltration"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 2.4, "condition": "Traitement infiltration"}
  }'),
  condition: "Traitement des infiltrations d'eau dans les murs.",
  conseil: "Diagnostic humidité préalable obligatoire.",
  document: "Rapport diagnostic + factures + garantie travaux",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/assechement_murs_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_assechement_murs_humidite").update!(
  titre: "Assèchement des murs - humidité ascensionnelle - Wallonie",
  ordre_affichage: 8,
  icon_name: "arrow-up",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 19.2, "condition": "Traitement humidité ascensionnelle"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 12.8, "condition": "Traitement humidité ascensionnelle"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 9.6, "condition": "Traitement humidité ascensionnelle"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 6.4, "condition": "Traitement humidité ascensionnelle"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 3.2, "condition": "Traitement humidité ascensionnelle"}
  }'),
  condition: "Traitement de l'humidité ascensionnelle dans les murs.",
  conseil: "Barrière étanche obligatoire. Ventilation renforcée.",
  document: "Rapport diagnostic + factures + garantie décennale",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/humidite_murs_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_renforcement_murs").update!(
  titre: "Renforcement des murs instables ou démolition/reconstruction - Wallonie",
  ordre_affichage: 9,
  icon_name: "hammer",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 19.2, "condition": "Renforcement structure"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 12.8, "condition": "Renforcement structure"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 9.6, "condition": "Renforcement structure"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 6.4, "condition": "Renforcement structure"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 3.2, "condition": "Renforcement structure"}
  }'),
  condition: "Renforcement ou reconstruction de murs instables.",
  conseil: "Expertise structure obligatoire avant travaux.",
  document: "Rapport structural + factures + attestation conformité",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/renforcement_murs_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_elimination_merule").update!(
  titre: "Élimination de la mérule - Wallonie",
  ordre_affichage: 10,
  icon_name: "bug",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 840, "condition": "Traitement complet mérule"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 560, "condition": "Traitement complet mérule"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 420, "condition": "Traitement complet mérule"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 280, "condition": "Traitement complet mérule"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 140, "condition": "Traitement complet mérule"}
  }'),
  condition: "Élimination complète de la mérule par entreprise agréée.",
  conseil: "Traitement obligatoire par professionnel certifié.",
  document: "Diagnostic + factures + garantie traitement",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/merule_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_elimination_radon").update!(
  titre: "Élimination du radon - Wallonie",
  ordre_affichage: 11,
  icon_name: "radiation",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 840, "condition": "Système anti-radon"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 560, "condition": "Système anti-radon"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 420, "condition": "Système anti-radon"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 280, "condition": "Système anti-radon"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 140, "condition": "Système anti-radon"}
  }'),
  condition: "Installation système de ventilation anti-radon.",
  conseil: "Mesure préalable concentration radon obligatoire.",
  document: "Mesures radon + factures + attestation efficacité",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/radon_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_isolation_murs").update!(
  titre: "Isolation thermique des murs - Wallonie",
  ordre_affichage: 12,
  icon_name: "brick-wall",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 52.8, "condition": "R ≥ 3,0 m²K/W"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 35.2, "condition": "R ≥ 3,0 m²K/W"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 26.4, "condition": "R ≥ 3,0 m²K/W"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 17.6, "condition": "R ≥ 3,0 m²K/W"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 8.8, "condition": "R ≥ 3,0 m²K/W"}
  }'),
  condition: "Murs en contact avec extérieur. R ≥ 3,0 m²K/W.",
  conseil: "ITE privilégiée pour ponts thermiques. ITI possible.",
  document: "Factures + plans + certificats isolants + photos",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/isolation_murs_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_isolation_murs_biosource").update!(
  titre: "Isolation thermique des murs BIOSOURCÉE - Wallonie",
  ordre_affichage: 13,
  icon_name: "leaf",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 72, "condition": "R ≥ 3,0 + biosourcé"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 48, "condition": "R ≥ 3,0 + biosourcé"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 36, "condition": "R ≥ 3,0 + biosourcé"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 24, "condition": "R ≥ 3,0 + biosourcé"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 12, "condition": "R ≥ 3,0 + biosourcé"}
  }'),
  condition: "Matériau biosourcé certifié. R ≥ 3,0 m²K/W.",
  conseil: "Prime majorée pour matériaux écologiques.",
  document: "Factures + certificat biosourcé + plans",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/isolation_murs_biosource_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === SOLS ===

Prime.find_or_initialize_by(slug: "wallonie_remplacement_supports_circulation").update!(
  titre: "Remplacement des supports des aires de circulation - Wallonie",
  ordre_affichage: 14,
  icon_name: "layer-group",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 12, "condition": "Remplacement supports"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 8, "condition": "Remplacement supports"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 6, "condition": "Remplacement supports"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 4, "condition": "Remplacement supports"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 2, "condition": "Remplacement supports"}
  }'),
  condition: "Remplacement des supports de planchers et aires de circulation.",
  conseil: "Diagnostic structure préalable recommandé.",
  document: "Factures + plans + photos avant/après",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Surface en m²",
    "wallonie_r2": "Surface en m²",
    "wallonie_r3": "Surface en m²",
    "wallonie_r4": "Surface en m²",
    "wallonie_r5": "Surface en m²"
  }'),
  image: "images/plancher_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_isolation_sols").update!(
  titre: "Isolation thermique des sols - Wallonie",
  ordre_affichage: 15,
  icon_name: "layer-group",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 36, "condition": "R ≥ 2,0 m²K/W"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 24, "condition": "R ≥ 2,0 m²K/W"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 18, "condition": "R ≥ 2,0 m²K/W"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 12, "condition": "R ≥ 2,0 m²K/W"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 6, "condition": "R ≥ 2,0 m²K/W"}
  }'),
  condition: "Sols en contact avec extérieur/local non chauffé. R ≥ 2,0 m²K/W.",
  conseil: "Isolation par dessous privilégiée si cave accessible.",
  document: "Factures + plans + certificats isolants",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/isolation_sols_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_isolation_sols_biosource").update!(
  titre: "Isolation thermique des sols BIOSOURCÉE - Wallonie",
  ordre_affichage: 16,
  icon_name: "leaf",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 48, "condition": "R ≥ 2,0 + biosourcé"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 32, "condition": "R ≥ 2,0 + biosourcé"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 24, "condition": "R ≥ 2,0 + biosourcé"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 16, "condition": "R ≥ 2,0 + biosourcé"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 8, "condition": "R ≥ 2,0 + biosourcé"}
  }'),
  condition: "Matériau biosourcé certifié. R ≥ 2,0 m²K/W.",
  conseil: "Prime majorée pour matériaux écologiques.",
  document: "Factures + certificat biosourcé + plans",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/isolation_sols_biosource_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_isolation_finition_planchers").update!(
  titre: "Isolation finition planchers - Wallonie",
  ordre_affichage: 17,
  icon_name: "grip-lines",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 12, "condition": "Finition isolante"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 8, "condition": "Finition isolante"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 6, "condition": "Finition isolante"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 4, "condition": "Finition isolante"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 2, "condition": "Finition isolante"}
  }'),
  condition: "Isolation et finition des planchers.",
  conseil: "Complémentaire à l'isolation principale.",
  document: "Factures + photos finition",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/finition_plancher_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === MENUISERIES ===

Prime.find_or_initialize_by(slug: "wallonie_menuiseries_vitrages").update!(
  titre: "Remplacement des menuiseries/vitrages extérieurs - Wallonie",
  ordre_affichage: 18,
  icon_name: "window",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 156, "condition": "Uw ≤ 1,3 W/m²K"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 104, "condition": "Uw ≤ 1,3 W/m²K"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 78, "condition": "Uw ≤ 1,3 W/m²K"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 52, "condition": "Uw ≤ 1,3 W/m²K"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 26, "condition": "Uw ≤ 1,3 W/m²K"}
  }'),
  condition: "Coefficient Uw ≤ 1,3 W/m²K. Triple vitrage recommandé.",
  conseil: "Mesurer surface vitrage. Pose étanche obligatoire.",
  document: "Factures + fiches techniques + mesures + photos",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "surface en m²",
    "wallonie_r2": "surface en m²",
    "wallonie_r3": "surface en m²",
    "wallonie_r4": "surface en m²",
    "wallonie_r5": "surface en m²"
  }'),
  image: "images/menuiseries_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === INSTALLATIONS ===

Prime.find_or_initialize_by(slug: "wallonie_installation_electrique").update!(
  titre: "Appropriation de l'installation électrique - Wallonie",
  ordre_affichage: 19,
  icon_name: "bolt",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 1920, "condition": "Mise aux normes"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 1280, "condition": "Mise aux normes"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 960, "condition": "Mise aux normes"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 640, "condition": "Mise aux normes"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 320, "condition": "Mise aux normes"}
  }'),
  condition: "Mise aux normes de l'installation électrique.",
  conseil: "Contrôle électricien agréé obligatoire.",
  document: "Certificat conformité + factures + rapport contrôle",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/electricite_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_installation_gaz").update!(
  titre: "Appropriation de l'installation de gaz - Wallonie",
  ordre_affichage: 20,
  icon_name: "fire",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 840, "condition": "Mise aux normes gaz"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 560, "condition": "Mise aux normes gaz"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 420, "condition": "Mise aux normes gaz"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 280, "condition": "Mise aux normes gaz"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 140, "condition": "Mise aux normes gaz"}
  }'),
  condition: "Mise aux normes de l'installation de gaz.",
  conseil: "Contrôle organisme agréé obligatoire.",
  document: "Certificat conformité + factures + rapport contrôle",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/gaz_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === CHAUFFAGE ===

Prime.find_or_initialize_by(slug: "wallonie_pac_eau_chaude").update!(
  titre: "Pompe à chaleur - eau chaude sanitaire (boiler thermodynamique) - Wallonie",
  ordre_affichage: 21,
  icon_name: "tint",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 1680, "condition": "COP ≥ 2,5"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 1120, "condition": "COP ≥ 2,5"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 840, "condition": "COP ≥ 2,5"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 560, "condition": "COP ≥ 2,5"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 280, "condition": "COP ≥ 2,5"}
  }'),
  condition: "COP ≥ 2,5. Volume minimal 200L. Installation intérieure.",
  conseil: "Local non chauffé recommandé. Évacuation condensats.",
  document: "Factures + fiche technique COP + photos installation",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/cet_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_pac_chauffage").update!(
  titre: "Pompe à chaleur - chauffage ou combinée air/eau ou air/sol - Wallonie",
  ordre_affichage: 22,
  icon_name: "thermometer-half",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 3600, "condition": "COP ≥ 3,5 à 7°C"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 2400, "condition": "COP ≥ 3,5 à 7°C"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 1800, "condition": "COP ≥ 3,5 à 7°C"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 1200, "condition": "COP ≥ 3,5 à 7°C"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 600, "condition": "COP ≥ 3,5 à 7°C"}
  }'),
  condition: "COP ≥ 3,5 à 7°C. Remplacement système combustible fossile.",
  conseil: "Dimensionnement par thermicien. Isolation préalable recommandée.",
  document: "Factures + fiche technique COP + attestation dépose ancien système",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/pac_air_eau_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chaudiere_biomasse").update!(
  titre: "Chaudière biomasse - Wallonie",
  ordre_affichage: 23,
  icon_name: "fire",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 4320, "condition": "Rendement ≥ 85%"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 2880, "condition": "Rendement ≥ 85%"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 2160, "condition": "Rendement ≥ 85%"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 1440, "condition": "Rendement ≥ 85%"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 720, "condition": "Rendement ≥ 85%"}
  }'),
  condition: "Rendement ≥ 85%. Combustible biomasse certifié.",
  conseil: "Stockage combustible adéquat. Conduit ramonage.",
  document: "Factures + certificat rendement + attestation combustible",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chaudiere_biomasse_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffe_eau_solaire").update!(
  titre: "Chauffe-eau solaire - Wallonie",
  ordre_affichage: 24,
  icon_name: "solar-panel",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 2520, "condition": "Certification Solar Keymark"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 1680, "condition": "Certification Solar Keymark"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 1260, "condition": "Certification Solar Keymark"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 840, "condition": "Certification Solar Keymark"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 420, "condition": "Certification Solar Keymark"}
  }'),
  condition: "Système complet certifié. Ballon minimal 200L.",
  conseil: "Orientation optimale 45° sud. Appoint électrique intégré.",
  document: "Factures + certificat Solar Keymark + plans + photos",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/ces_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_poele_biomasse").update!(
  titre: "Poêle biomasse local - Wallonie",
  ordre_affichage: 25,
  icon_name: "fire-alt",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 960, "condition": "Rendement ≥ 80%"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 640, "condition": "Rendement ≥ 80%"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 480, "condition": "Rendement ≥ 80%"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 320, "condition": "Rendement ≥ 80%"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 160, "condition": "Rendement ≥ 80%"}
  }'),
  condition: "Rendement ≥ 80%. Combustible biomasse certifié.",
  conseil: "Installation conduit conforme. Ventilation suffisante.",
  document: "Factures + certificat rendement + attestation installation",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/poele_biomasse_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === VENTILATION ===
Prime.find_or_initialize_by(slug: "wallonie_vmc_simple").update!(
  titre: "Ventilation - VMC simple flux toutes les pièces humides - Wallonie",
  ordre_affichage: 26,
  icon_name: "wind",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 1680, "condition": "Hygroréglable"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 1120, "condition": "Hygroréglable"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 840, "condition": "Hygroréglable"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 560, "condition": "Hygroréglable"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 280, "condition": "Hygroréglable"}
  }'),
  condition: "Système hygroréglable. Entrées air neuves humidostatiques.",
  conseil: "Bouches hygroréglables dans pièces humides obligatoires.",
  document: "Factures + fiche technique + schéma installation",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/vsf_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_vmc_double").update!(
  titre: "Ventilation - VMC double flux avec récupération de chaleur - Wallonie",
  ordre_affichage: 27,
  icon_name: "fan",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 4080, "condition": "Efficacité ≥ 85%"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 2720, "condition": "Efficacité ≥ 85%"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 2040, "condition": "Efficacité ≥ 85%"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 1360, "condition": "Efficacité ≥ 85%"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 680, "condition": "Efficacité ≥ 85%"}
  }'),
  condition: "Efficacité récupération ≥ 85%. Réseau étanche.",
  conseil: "Dimensionnement selon RT 2012. Entretien filtres régulier.",
  document: "Factures + fiche efficacité + plan réseau + réception",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/vdf_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_vmc_simple_partielle").update!(
  titre: "Ventilation - VMC simple flux (partielle, pièces humides uniquement) - Wallonie",
  ordre_affichage: 28,
  icon_name: "wind",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 480, "condition": "Hygroréglable partiel"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 320, "condition": "Hygroréglable partiel"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 240, "condition": "Hygroréglable partiel"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 160, "condition": "Hygroréglable partiel"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 80, "condition": "Hygroréglable partiel"}
  }'),
  condition: "Système hygroréglable partiel. Pièces humides uniquement.",
  conseil: "Solution économique pour petits logements.",
  document: "Factures + fiche technique + plan installation",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/vsf_partielle_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_vmc_double_partielle").update!(
  titre: "Ventilation - VMC double flux (partielle, pièces humides uniquement) - Wallonie",
  ordre_affichage: 29,
  icon_name: "fan",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 960, "condition": "Efficacité ≥ 75%"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 640, "condition": "Efficacité ≥ 75%"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 480, "condition": "Efficacité ≥ 75%"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 320, "condition": "Efficacité ≥ 75%"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 160, "condition": "Efficacité ≥ 75%"}
  }'),
  condition: "Efficacité récupération ≥ 75%. Installation partielle.",
  conseil: "Solution intermédiaire avec récupération de chaleur.",
  document: "Factures + fiche efficacité + plan installation",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/vdf_partielle_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

# === AMÉLIORATIONS CHAUFFAGE ===
Prime.find_or_initialize_by(slug: "wallonie_chauffage_isol_conduites").update!(
  titre: "Amélioration chauffage - Isolation des conduites de chauffage (hors volume protégé) - Wallonie",
  ordre_affichage: 30,
  icon_name: "pipe",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 204, "condition": "Isolation conduites"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 136, "condition": "Isolation conduites"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 102, "condition": "Isolation conduites"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 68, "condition": "Isolation conduites"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 34, "condition": "Isolation conduites"}
  }'),
  condition: "Isolation des conduites situées hors volume protégé.",
  conseil: "Matériau isolant adapté aux hautes températures.",
  document: "Factures + photos avant/après + plan conduites",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/isolation_conduites_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_isol_ballon_500").update!(
  titre: "Amélioration chauffage - Isolation ballon ≤500l - Wallonie",
  ordre_affichage: 31,
  icon_name: "thermometer-quarter",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 120, "condition": "Ballon ≤500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 80, "condition": "Ballon ≤500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 60, "condition": "Ballon ≤500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 40, "condition": "Ballon ≤500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 20, "condition": "Ballon ≤500l"}
  }'),
  condition: "Isolation de ballon de chauffage ≤500 litres.",
  conseil: "Matériau isolant résistant à la température.",
  document: "Factures + photos ballon + caractéristiques volume",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/ballon_chauffage_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_isol_ballon_sup").update!(
  titre: "Amélioration chauffage - Isolation ballon >500l - Wallonie",
  ordre_affichage: 32,
  icon_name: "thermometer-half",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 204, "condition": "Ballon >500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 136, "condition": "Ballon >500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 102, "condition": "Ballon >500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 68, "condition": "Ballon >500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 34, "condition": "Ballon >500l"}
  }'),
  condition: "Isolation de ballon de chauffage >500 litres.",
  conseil: "Isolation renforcée pour gros volumes.",
  document: "Factures + photos ballon + caractéristiques volume",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/ballon_chauffage_sup_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_circ_3logt").update!(
  titre: "Amélioration chauffage - Circulateur (max 3 logements) - Wallonie",
  ordre_affichage: 33,
  icon_name: "cog",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 84, "condition": "Max 3 logements"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 56, "condition": "Max 3 logements"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 42, "condition": "Max 3 logements"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 28, "condition": "Max 3 logements"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 14, "condition": "Max 3 logements"}
  }'),
  condition: "Circulateur haute performance pour maximum 3 logements.",
  conseil: "Circulateur classe A obligatoire.",
  document: "Factures + fiche technique classe énergétique",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/circulateur_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_circ_4logt").update!(
  titre: "Amélioration chauffage - Circulateur (min 4 logements) - Wallonie",
  ordre_affichage: 34,
  icon_name: "cogs",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 456, "condition": "Min 4 logements"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 304, "condition": "Min 4 logements"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 228, "condition": "Min 4 logements"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 152, "condition": "Min 4 logements"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 76, "condition": "Min 4 logements"}
  }'),
  condition: "Circulateur haute performance pour minimum 4 logements.",
  conseil: "Installation collective. Circulateur classe A++.",
  document: "Factures + fiche technique + attestation logements",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/circulateur_collectif_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_ballon_500").update!(
  titre: "Amélioration chauffage - Remplacement ballon ≤500l - Wallonie",
  ordre_affichage: 35,
  icon_name: "exchange-alt",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 240, "condition": "Remplacement ≤500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 160, "condition": "Remplacement ≤500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 120, "condition": "Remplacement ≤500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 80, "condition": "Remplacement ≤500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 40, "condition": "Remplacement ≤500l"}
  }'),
  condition: "Remplacement ballon chauffage ≤500 litres par modèle performant.",
  conseil: "Ballon haute performance énergétique obligatoire.",
  document: "Factures + attestation dépose ancien + fiche technique nouveau",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/remplacement_ballon_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_ballon_sup").update!(
  titre: "Amélioration chauffage - Remplacement ballon >500l - Wallonie",
  ordre_affichage: 36,
  icon_name: "exchange-alt",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 408, "condition": "Remplacement >500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 272, "condition": "Remplacement >500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 204, "condition": "Remplacement >500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 136, "condition": "Remplacement >500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 68, "condition": "Remplacement >500l"}
  }'),
  condition: "Remplacement ballon chauffage >500 litres par modèle performant.",
  conseil: "Ballon haute performance pour gros volumes.",
  document: "Factures + attestation dépose ancien + fiche technique nouveau",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/remplacement_ballon_sup_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_vannes_base").update!(
  titre: "Amélioration chauffage - minimum 5 vannes thermostatiques - Wallonie",
  ordre_affichage: 37,
  icon_name: "sliders-h",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 120, "condition": "Min 5 vannes"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 80, "condition": "Min 5 vannes"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 60, "condition": "Min 5 vannes"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 40, "condition": "Min 5 vannes"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 20, "condition": "Min 5 vannes"}
  }'),
  condition: "Installation de minimum 5 vannes thermostatiques.",
  conseil: "Vannes programmables recommandées pour optimisation.",
  document: "Factures + photos vannes + plan radiateurs",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/vannes_thermostatiques_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_vannes_sup").update!(
  titre: "Amélioration chauffage - supplémentaire aux 5 vannes thermostatiques de base - Wallonie",
  ordre_affichage: 38,
  icon_name: "plus-square",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_par_unite", "montant_unitaire": 24, "condition": "Vannes supplémentaires"},
    "wallonie_r2": {"type": "montant_par_unite", "montant_unitaire": 16, "condition": "Vannes supplémentaires"},
    "wallonie_r3": {"type": "montant_par_unite", "montant_unitaire": 12, "condition": "Vannes supplémentaires"},
    "wallonie_r4": {"type": "montant_par_unite", "montant_unitaire": 8, "condition": "Vannes supplémentaires"},
    "wallonie_r5": {"type": "montant_par_unite", "montant_unitaire": 4, "condition": "Vannes supplémentaires"}
  }'),
  condition: "Vannes thermostatiques supplémentaires au-delà des 5 de base.",
  conseil: "Prime par groupe de 5 vannes supplémentaires.",
  document: "Factures + décompte total vannes + photos",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Nombre de vannes",
    "wallonie_r2": "Nombre de vannes",
    "wallonie_r3": "Nombre de vannes",
    "wallonie_r4": "Nombre de vannes",
    "wallonie_r5": "Nombre de vannes"
  }'),
  image: "images/vannes_sup_wallonie.webp",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_chauffage_thermostat").update!(
  titre: "Amélioration chauffage - Thermostat d'ambiance - Wallonie",
  ordre_affichage: 40,
  icon_name: "thermometer-three-quarters",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 96, "condition": "Thermostat programmable"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 64, "condition": "Thermostat programmable"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 48, "condition": "Thermostat programmable"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 32, "condition": "Thermostat programmable"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 16, "condition": "Thermostat programmable"}
  }'),
  condition: "Voir conditions techniques spécifiques sur le site officiel.",
  conseil: "Faites appel à un professionnel certifié pour la pose et la conformité.",
  document: "Facture détaillée + certificat de conformité ou attestation de performance",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)
# === ECS (EAU CHAUDE SANITAIRE) ===


Prime.find_or_initialize_by(slug: "wallonie_ecs_ballon_500").update!(
  titre: "ECS - Remplacement ballon ≤500l - Wallonie",
  ordre_affichage: 41,
  icon_name: "water-tank",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 288, "condition": "Ballon ≤500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 192, "condition": "Ballon ≤500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 144, "condition": "Ballon ≤500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 96, "condition": "Ballon ≤500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 48, "condition": "Ballon ≤500l"}
  }'),
  condition: "Voir conditions techniques spécifiques sur le site officiel.",
  conseil: "Faites appel à un professionnel certifié pour la pose et la conformité.",
  document: "Facture détaillée + certificat de conformité ou attestation de performance",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_ecs_ballon_sup").update!(
  titre: "ECS - Remplacement ballon >500l - Wallonie",
  ordre_affichage: 42,
  icon_name: "water-tank-large",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 432, "condition": "Ballon >500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 288, "condition": "Ballon >500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 216, "condition": "Ballon >500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 144, "condition": "Ballon >500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 72, "condition": "Ballon >500l"}
  }'),
  condition: "Voir conditions techniques spécifiques sur le site officiel.",
  conseil: "Faites appel à un professionnel certifié pour la pose et la conformité.",
  document: "Facture détaillée + certificat de conformité ou attestation de performance",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_ecs_conduites_coll").update!(
  titre: "ECS - Isolation conduites boucle circulation (collective) - Wallonie",
  ordre_affichage: 43,
  icon_name: "pipe-isolation",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 120, "condition": "Isolation conduites collective"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 80, "condition": "Isolation conduites collective"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 60, "condition": "Isolation conduites collective"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 40, "condition": "Isolation conduites collective"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 20, "condition": "Isolation conduites collective"}
  }'),
  condition: "Voir conditions techniques spécifiques sur le site officiel.",
  conseil: "Faites appel à un professionnel certifié pour la pose et la conformité.",
  document: "Facture détaillée + certificat de conformité ou attestation de performance",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_ecs_echangeur").update!(
  titre: "ECS - Isolation échangeur plaques externe - Wallonie",
  ordre_affichage: 44,
  icon_name: "heat-exchanger",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 204, "condition": "Échangeur plaques externe"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 136, "condition": "Échangeur plaques externe"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 102, "condition": "Échangeur plaques externe"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 68, "condition": "Échangeur plaques externe"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 34, "condition": "Échangeur plaques externe"}
  }'),
  condition: "Voir conditions techniques spécifiques sur le site officiel.",
  conseil: "Faites appel à un professionnel certifié pour la pose et la conformité.",
  document: "Facture détaillée + certificat de conformité ou attestation de performance",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_ecs_isol_ballon_500").update!(
  titre: "ECS - Isolation ballon ≤500l - Wallonie",
  ordre_affichage: 45,
  icon_name: "water-tank-insulation",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 120, "condition": "Isolation ballon ≤500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 80, "condition": "Isolation ballon ≤500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 60, "condition": "Isolation ballon ≤500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 40, "condition": "Isolation ballon ≤500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 20, "condition": "Isolation ballon ≤500l"}
  }'),
  condition: "Voir conditions techniques spécifiques sur le site officiel.",
  conseil: "Faites appel à un professionnel certifié pour la pose et la conformité.",
  document: "Facture détaillée + certificat de conformité ou attestation de performance",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

Prime.find_or_initialize_by(slug: "wallonie_ecs_isol_ballon_sup").update!(
  titre: "ECS - Isolation ballon >500l - Wallonie",
  ordre_affichage: 46,
  icon_name: "water-tank-insulation-large",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 204, "condition": "Isolation ballon >500l"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 136, "condition": "Isolation ballon >500l"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 102, "condition": "Isolation ballon >500l"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 68, "condition": "Isolation ballon >500l"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 34, "condition": "Isolation ballon >500l"}
  }'),
  condition: "Voir conditions techniques spécifiques sur le site officiel.",
  conseil: "Faites appel à un professionnel certifié pour la pose et la conformité.",
  document: "Facture détaillée + certificat de conformité ou attestation de performance",
  specifique: "Wallonie - Primes Habitation",
  placeholder: JSON.parse('{
    "wallonie_r1": "Forfaitaire - 1 ou 0",
    "wallonie_r2": "Forfaitaire - 1 ou 0",
    "wallonie_r3": "Forfaitaire - 1 ou 0",
    "wallonie_r4": "Forfaitaire - 1 ou 0",
    "wallonie_r5": "Forfaitaire - 1 ou 0"
  }'),
  image: "images/chauffage.jpg",
  region: "wallonie",
  category_id: Category.find_by(code: "wallonie_r1", region: "wallonie")&.id
)

puts "✅ #{Prime.where(region: 'wallonie').count} primes Wallonie créées avec succès"
