# =====================================================
# PRIMES WALLONIE - ECS (EAU CHAUDE SANITAIRE)
# =====================================================
# Module pour les primes ECS (6 primes)
# =====================================================

puts "🚿 Création des primes ECS (Eau Chaude Sanitaire) Wallonie..."

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
  condition: "Remplacement d'un réservoir de stockage pour l'eau chaude sanitaire ≤500l. Le réservoir ne doit PAS être équipé d'une résistance électrique. Le système doit permettre de prévenir le risque de légionellose et être muni d'un groupe de sécurité classique. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Installation sans résistance électrique obligatoire. Système anti-légionellose et groupe de sécurité requis pour la conformité sanitaire.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + fiche technique du réservoir + attestation absence résistance électrique + certificat système anti-légionellose + annexe technique 6 complétée et signée + preuve d'enregistrement BCE du contractant",
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
  condition: "Remplacement d'un réservoir de stockage pour l'eau chaude sanitaire >500l. Le réservoir ne doit PAS être équipé d'une résistance électrique. Le système doit permettre de prévenir le risque de légionellose et être muni d'un groupe de sécurité classique. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Installation sans résistance électrique obligatoire pour gros volumes. Système anti-légionellose et groupe de sécurité renforcés requis.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + fiche technique du réservoir + attestation absence résistance électrique + certificat système anti-légionellose + annexe technique 6 complétée et signée + preuve d'enregistrement BCE du contractant",
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
  condition: "Isolation des conduites d'une boucle de circulation d'eau chaude sanitaire et ses accessoires en installation collective. Le calorifugeage des conduites de la boucle de circulation d'eau chaude sanitaire et de ses accessoires doit répondre aux exigences de l'annexe C4 de l'Arrêté du Gouvernement wallon du 15 mai 2014. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Travaux exclusivement pour installation collective. Respect obligatoire des exigences annexe C4 pour le calorifugeage.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + rapport relatif au calorifugeage des tuyaux d'eau chaude selon l'annexe C4 rédigé par l'installateur + annexe technique 6 complétée et signée + preuve d'enregistrement BCE du contractant",
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
  condition: "Isolation d'un échangeur à plaques externe pour l'eau chaude sanitaire au moyen d'un matériau isolant possédant un coefficient de résistance thermique R ≥ 1,50 m²K/W. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Matériau isolant haute performance avec coefficient R ≥ 1,50 m²K/W obligatoire. Installation par professionnel qualifié recommandée.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + fiche technique du matériau isolant avec coefficient R + certificat de performance thermique + annexe technique 6 complétée et signée + preuve d'enregistrement BCE du contractant",
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
  condition: "Isolation d'un ballon de stockage pour l'eau chaude sanitaire ≤500l au moyen d'un matériau isolant possédant un coefficient de résistance thermique R ≥ 1,50 m²K/W. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Isolation thermique haute performance avec coefficient R ≥ 1,50 m²K/W obligatoire. Amélioration significative de l'efficacité énergétique.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + fiche technique du matériau isolant avec coefficient R + certificat de performance thermique + annexe technique 6 complétée et signée + preuve d'enregistrement BCE du contractant",
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
  condition: "Isolation d'un ballon de stockage pour l'eau chaude sanitaire >500l au moyen d'un matériau isolant possédant un coefficient de résistance thermique R ≥ 1,50 m²K/W. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Isolation thermique haute performance avec coefficient R ≥ 1,50 m²K/W obligatoire pour gros volumes. Économies d'énergie importantes.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + fiche technique du matériau isolant avec coefficient R + certificat de performance thermique + annexe technique 6 complétée et signée + preuve d'enregistrement BCE du contractant",
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

puts "✅ Primes ECS (Eau Chaude Sanitaire) Wallonie créées avec succès (6 primes)"
