# =====================================================
# PRIMES WALLONIE - VENTILATION
# =====================================================
# Module pour les primes de ventilation (4 primes)
# =====================================================

puts "💨 Création des primes Ventilation Wallonie..."

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
  condition: "Installation d'un système centralisé de ventilation mécanique simple flux qui assure la ventilation de l'ensemble des espaces du logement. L'installation doit respecter les exigences de la section ventilation de l'annexe C4, les prescriptions de l'annexe C2 et, le cas échéant, de l'annexe C3 de l'Arrêté du Gouvernement wallon du 15 mai 2014. L'installation doit être équipée d'une fonctionnalité à la demande selon l'arrêté ministériel du 16 octobre 2015. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Système centralisé avec fonctionnalité à la demande obligatoire. Bouches hygroréglables dans toutes les pièces humides. Respect strict des annexes C4, C2 et C3.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + annexe technique 7 complétée, datée et signée par l'entrepreneur + rapport de mesure attestant des débits de ventilation effectivement mis en œuvre et de leur conformité PEB + attestation capacité ouvertures de ventilation naturelle + preuve d'enregistrement BCE du contractant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r5": {"type": "montant_fixe", "montant": 680, "condition": "Efficacité ≥ 78%"}
  }'),
  condition: "Installation d'un système centralisé de ventilation mécanique double flux qui assure la ventilation de l'ensemble des espaces du logement. L'installation doit respecter les exigences de la section ventilation de l'annexe C4, les prescriptions de l'annexe C2 et, le cas échéant, de l'annexe C3 de l'Arrêté du Gouvernement wallon du 15 mai 2014. L'installation doit être équipée d'un dispositif de récupération de chaleur d'une efficacité minimale de 78% selon la NBN EN 308, complétée par l'annexe G. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Système centralisé avec récupération de chaleur d'efficacité minimale 78% selon NBN EN 308. Réseau étanche obligatoire. Vérifier présence du récupérateur sur base EPBD (www.epbd.be).",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + annexe technique 7 complétée, datée et signée par l'entrepreneur + rapport de mesure attestant des débits de ventilation + rapport de test du récupérateur selon NBN EN 308 si non présent sur base EPBD + preuve d'enregistrement BCE du contractant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  condition: "Installation d'un système de ventilation mécanique simple flux qui assure la ventilation d'une partie des espaces du logement. L'installation doit respecter les exigences de la section ventilation de l'annexe C4, les prescriptions de l'annexe C2 et, le cas échéant, de l'annexe C3 de l'Arrêté du Gouvernement wallon du 15 mai 2014. L'installation doit être équipée d'une régulation du débit par détection : toilettes (présence, CO2 ou couplage éclairage), cuisine (CO2 ou humidité), autres espaces humides (humidité). Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Système partiel avec régulation obligatoire par détection selon le type d'espace. Toilettes : détection présence/CO2/couplage éclairage. Cuisine : détection CO2/humidité. SDD/SDB/buanderie : détection humidité.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + annexe technique 7 complétée, datée et signée par l'entrepreneur + rapport de mesure des débits de ventilation PEB + fiche technique de l'appareil si dessert un seul espace + preuve d'enregistrement BCE du contractant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r5": {"type": "montant_fixe", "montant": 160, "condition": "Efficacité ≥ 50%"}
  }'),
  condition: "Installation d'un système de ventilation mécanique double flux qui assure la ventilation d'une partie des espaces du logement. L'installation doit respecter les exigences de la section ventilation de l'annexe C4, les prescriptions de l'annexe C2 et, le cas échéant, de l'annexe C3 de l'Arrêté du Gouvernement wallon du 15 mai 2014. L'installation doit comporter, pour chaque groupe de ventilation, un dispositif de récupération de chaleur d'une efficacité minimale de 50% selon l'annexe G. Le contractant doit être enregistré à la Banque-Carrefour des Entreprises (BCE).",
  conseil: "Système partiel avec récupération de chaleur d'efficacité minimale 50% par groupe de ventilation. Vérifier présence du récupérateur sur base EPBD (www.epbd.be) pour éviter rapport de test supplémentaire.",
  document: "Factures détaillées mentionnant clairement les montants des différents éléments + annexe technique 7 complétée, datée et signée par l'entrepreneur + rapport de mesure des débits de ventilation PEB + rapport de test du rendement du récupérateur selon NBN EN 308 si non présent sur base EPBD + preuve d'enregistrement BCE du contractant",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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

puts "✅ Primes Ventilation Wallonie créées avec succès (4 primes)"
