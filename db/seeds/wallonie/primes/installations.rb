# =====================================================
# PRIMES WALLONIE - INSTALLATIONS
# =====================================================
# Module pour les primes d'installations (2 primes)
# =====================================================

puts "⚡ Création des primes Installations Wallonie..."

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
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  statut_compatible: "12 mois à partir de la date de facture de solde",
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

puts "✅ Primes Installations Wallonie créées avec succès (2 primes)"
