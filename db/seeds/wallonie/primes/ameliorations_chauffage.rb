# =====================================================
# PRIMES WALLONIE - AMÉLIORATIONS CHAUFFAGE
# =====================================================
# Module pour les primes d'amélioration du chauffage (10 primes)
# =====================================================

puts "🔧 Création des primes Améliorations Chauffage Wallonie..."

# === AMÉLIORATIONS CHAUFFAGE ===

Prime.find_or_initialize_by(slug: "wallonie_chauffage_isol_conduites").update!(
  titre: "Amélioration chauffage - Isolation des conduites de chauffage et accessoires - Wallonie",
  ordre_affichage: 30,
  icon_name: "pipe",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 204, "condition": "Calorifugeage annexe C4 arrêté 15/05/2014"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 136, "condition": "Calorifugeage annexe C4 arrêté 15/05/2014"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 102, "condition": "Calorifugeage annexe C4 arrêté 15/05/2014"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 68, "condition": "Calorifugeage annexe C4 arrêté 15/05/2014"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 34, "condition": "Calorifugeage annexe C4 arrêté 15/05/2014"}
  }'),
  condition: "Conduites chauffage et accessoires situées dans espace non chauffé (à l'abri du gel ou non). Calorifugeage conforme annexe C4 Arrêté 15/05/2014 (performance énergétique bâtiments).",
  conseil: "Matériau isolant adapté aux hautes températures. Inclut accessoires système chauffage.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Rapport calorifugeage tuyaux eau chaude annexe C4 rédigé par installateur + Photos avant/après",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r1": {"type": "montant_fixe", "montant": 120, "condition": "Ballon ≤500l + R ≥ 1,50 m²K/W"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 80, "condition": "Ballon ≤500l + R ≥ 1,50 m²K/W"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 60, "condition": "Ballon ≤500l + R ≥ 1,50 m²K/W"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 40, "condition": "Ballon ≤500l + R ≥ 1,50 m²K/W"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 20, "condition": "Ballon ≤500l + R ≥ 1,50 m²K/W"}
  }'),
  condition: "Isolation ballon stockage chauffage ≤500 litres. Matériau isolant coefficient résistance thermique R ≥ 1,50 m²K/W.",
  conseil: "Matériau isolant résistant à la température. Vérifier coefficient R isolant.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos ballon + Caractéristiques volume + Certificat coefficient R isolant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r1": {"type": "montant_fixe", "montant": 204, "condition": "Ballon >500l + R ≥ 1,50 m²K/W"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 136, "condition": "Ballon >500l + R ≥ 1,50 m²K/W"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 102, "condition": "Ballon >500l + R ≥ 1,50 m²K/W"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 68, "condition": "Ballon >500l + R ≥ 1,50 m²K/W"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 34, "condition": "Ballon >500l + R ≥ 1,50 m²K/W"}
  }'),
  condition: "Isolation ballon stockage chauffage >500 litres. Matériau isolant coefficient résistance thermique R ≥ 1,50 m²K/W.",
  conseil: "Isolation renforcée pour gros volumes. Vérifier coefficient R isolant.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos ballon + Caractéristiques volume + Certificat coefficient R isolant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  condition: "Installation de circulateurs à vitesse variable pour maximum 3 logements. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Circulateurs à vitesse variable classe A++ obligatoires. Modulation automatique selon les besoins du circuit de chauffage.",
  document: "Factures détaillées + fiche technique avec classe énergétique + annexe technique 6 complétée + preuve d'enregistrement BCE du contractant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  condition: "Installation de circulateurs à vitesse variable pour minimum 4 logements en habitat collectif. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Installation collective. Circulateurs à vitesse variable classe A++ avec régulation automatique selon les besoins du circuit de chauffage.",
  document: "Factures détaillées + fiche technique avec classe énergétique + annexe technique 6 complétée + attestation nombre de logements + preuve d'enregistrement BCE du contractant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  condition: "Remplacement d'un ballon de stockage de chauffage ≤500 litres par un modèle haute performance énergétique. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Ballon de stockage haute performance énergétique obligatoire avec isolation renforcée. Respect des normes européennes en vigueur.",
  document: "Factures détaillées + attestation de dépose de l'ancien ballon + fiche technique du nouveau ballon avec performances énergétiques + annexe technique 6 complétée + preuve d'enregistrement BCE du contractant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  condition: "Remplacement d'un ballon de stockage de chauffage >500 litres par un modèle haute performance énergétique. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Ballon de stockage haute performance pour gros volumes avec isolation thermique renforcée. Respect des normes européennes en vigueur.",
  document: "Factures détaillées + attestation de dépose de l'ancien ballon + fiche technique du nouveau ballon avec performances énergétiques + annexe technique 6 complétée + preuve d'enregistrement BCE du contractant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  condition: "Installation de minimum 5 vannes thermostatiques de régulation avec régulation de température ambiante. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Vannes thermostatiques programmables recommandées pour une régulation optimale de la température ambiante. Installation sur radiateurs existants.",
  document: "Factures détaillées + photos avant/après installation + plan de situation des radiateurs équipés + annexe technique 6 complétée + preuve d'enregistrement BCE du contractant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  condition: "Vannes thermostatiques de régulation supplémentaires au-delà des 5 de base. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Prime accordée pour chaque vanne supplémentaire au-delà du minimum requis de 5 vannes. Régulation de température ambiante obligatoire.",
  document: "Factures détaillées + décompte exact du nombre total de vannes installées + photos + annexe technique 6 complétée + preuve d'enregistrement BCE du contractant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  condition: "Installation d'un thermostat d'ambiance programmable avec fonction d'arrêt automatique du producteur de chaleur et des circulateurs. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Thermostat programmable obligatoire avec capacité d'arrêt automatique des systèmes de production et circulation. Installation par professionnel certifié recommandée.",
  document: "Factures détaillées + fiche technique du thermostat + attestation de fonctionnalité d'arrêt automatique + annexe technique 6 complétée + preuve d'enregistrement BCE du contractant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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

puts "✅ Primes Améliorations Chauffage Wallonie créées avec succès (10 primes)"
