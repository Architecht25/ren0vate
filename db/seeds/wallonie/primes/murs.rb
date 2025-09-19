# =====================================================
# PRIMES WALLONIE - MURS
# =====================================================
# Module pour les primes de murs (7 primes)
# =====================================================

puts "🧱 Création des primes Murs Wallonie..."

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
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 52.8, "condition": "R ≥ 4,00 m²K/W - Entrepreneur BCE"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 35.2, "condition": "R ≥ 4,00 m²K/W - Entrepreneur BCE"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 26.4, "condition": "R ≥ 4,00 m²K/W - Entrepreneur BCE"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 17.6, "condition": "R ≥ 4,00 m²K/W - Entrepreneur BCE"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 8.8, "condition": "R ≥ 4,00 m²K/W - Entrepreneur BCE"}
  }'),
  condition: "Entrepreneur BCE enregistré. Murs contact extérieur/espace non chauffé/sol. R ≥ 4,00 m²K/W (3,50 si demande avant 30/06/2024). Multicouches acceptées. Lambda certifié ATG/ETA/CE ou base EPBD. Paroi existante au jour audit. Travaux liés obligatoires sur même paroi.",
  conseil: "ITE privilégiée pour ponts thermiques. Possible assèchement/renforcement murs si nécessaire.",
  document: "Factures détaillées + Annexe technique 2 complétée/signée + Photos avant/pendant/après + Certificats lambda isolants",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 72, "condition": "R ≥ 4,00 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 48, "condition": "R ≥ 4,00 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 36, "condition": "R ≥ 4,00 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 24, "condition": "R ≥ 4,00 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 12, "condition": "R ≥ 4,00 m²K/W + biosourcé - Entrepreneur BCE"}
  }'),
  condition: "Entrepreneur BCE enregistré. Matériau biosourcé certifié. Murs contact extérieur/espace non chauffé/sol. R ≥ 4,00 m²K/W (3,50 si demande avant 30/06/2024). Multicouches acceptées. Lambda certifié ATG/ETA/CE ou base EPBD. Paroi existante au jour audit. Travaux liés obligatoires sur même paroi.",
  conseil: "Prime majorée pour matériaux écologiques. Possible assèchement/renforcement murs si nécessaire.",
  document: "Factures détaillées + Certificat biosourcé + Annexe technique 2 complétée/signée + Photos avant/pendant/après + Certificats lambda isolants",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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

puts "✅ Primes Murs Wallonie créées avec succès (7 primes)"
