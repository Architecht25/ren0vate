# =====================================================
# PRIMES WALLONIE - MENUISERIES
# =====================================================
# Module pour les primes de menuiseries (1 prime)
# =====================================================

puts "🪟 Création des primes Menuiseries Wallonie..."

# === MENUISERIES ===

Prime.find_or_initialize_by(slug: "wallonie_menuiseries_vitrages").update!(
  titre: "Remplacement des menuiseries/vitrages extérieurs - Wallonie",
  ordre_affichage: 18,
  icon_name: "window",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 156, "condition": "Uw ≤ 1,50 W/m²K + Ug ≤ 1,10 W/m²K - Entrepreneur BCE + accès profession"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 104, "condition": "Uw ≤ 1,50 W/m²K + Ug ≤ 1,10 W/m²K - Entrepreneur BCE + accès profession"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 78, "condition": "Uw ≤ 1,50 W/m²K + Ug ≤ 1,10 W/m²K - Entrepreneur BCE + accès profession"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 52, "condition": "Uw ≤ 1,50 W/m²K + Ug ≤ 1,10 W/m²K - Entrepreneur BCE + accès profession"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 26, "condition": "Uw ≤ 1,50 W/m²K + Ug ≤ 1,10 W/m²K - Entrepreneur BCE + accès profession"}
  }'),
  condition: "Entrepreneur BCE enregistré + accès profession. Contact extérieur/espace non chauffé. Ug vitrage ≤ 1,10 W/m²K (NBN EN 673). Éléments transparents/translucides ≤ 1,10 W/m²K. Vitrages norme NBN S23-002. Uw menuiseries ≤ 1,50 W/m²K (annexe B1 arrêté 15/05/2014).",
  conseil: "Mesurer surface vitrage précisément. Pose étanche obligatoire. Coordination portes/fenêtres.",
  document: "Factures détaillées + Annexe technique 4 complétée/signée + Bordereau menuiseries (surfaces + coefficients transmission thermique) + Fiches techniques + Photos",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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

puts "✅ Primes Menuiseries Wallonie créées avec succès (1 prime)"
