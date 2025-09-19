# =====================================================
# PRIMES WALLONIE - CHAUFFAGE
# =====================================================
# Module pour les primes de chauffage (5 primes)
# =====================================================

puts "🔥 Création des primes Chauffage Wallonie..."

# === CHAUFFAGE ===

Prime.find_or_initialize_by(slug: "wallonie_pac_eau_chaude").update!(
  titre: "Pompe à chaleur - eau chaude sanitaire (boiler thermodynamique) - Wallonie",
  ordre_affichage: 21,
  icon_name: "tint",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_fixe", "montant": 1680, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 1120, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 840, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 560, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 280, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"}
  }'),
  condition: "PAC reprise liste éligible energie.wallonie.be (sinon mail primeshabitation@spw.wallonie.be). Installateur certifié rescert.be (dès 01/01/2026) + BCE + accès profession. Prévention légionellose. Groupe sécurité classique.",
  conseil: "Vérifier éligibilité sur energie.wallonie.be. Local non chauffé recommandé. Évacuation condensats.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos source chaleur + Offre-type complétée/signée (dès 01/01/2026) + Si hors liste: étiquette énergétique règlement 812/2013 ou fiche Ecodesign 814/2013",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r1": {"type": "montant_fixe", "montant": 3600, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026) - EXCLU AIR/AIR"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 2400, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026) - EXCLU AIR/AIR"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 1800, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026) - EXCLU AIR/AIR"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 1200, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026) - EXCLU AIR/AIR"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 600, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026) - EXCLU AIR/AIR"}
  }'),
  condition: "PAC reprise liste éligible energie.wallonie.be (sinon mail primeshabitation@spw.wallonie.be). Installateur certifié rescert.be (dès 01/01/2026) + BCE + accès profession. EXCLUSION: PAC AIR/AIR non éligibles (rejet énergie thermique sur air).",
  conseil: "Dimensionnement par thermicien. Isolation préalable recommandée. Vérifier éligibilité sur energie.wallonie.be.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos source chaleur + Offre-type complétée/signée (dès 01/01/2026) + Si hors liste: fiche EcoDesign règlement 813/2013 ou rapport test NBN EN 14511/15879-1",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r1": {"type": "montant_fixe", "montant": 4320, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 2880, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 2160, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 1440, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 720, "condition": "Liste éligible energie.wallonie.be - Installateur certifié (2026)"}
  }'),
  condition: "Chaudière reprise liste éligible energie.wallonie.be (sinon mail primeshabitation@spw.wallonie.be + rapport test fabricant). Installateur certifié rescert.be (dès 01/01/2026) + BCE + accès profession.",
  conseil: "Stockage combustible adéquat. Conduit ramonage. Vérifier éligibilité sur energie.wallonie.be.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos démonstrant effectivité + Si hors liste: rapport test NBN EN 303-5",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r1": {"type": "montant_fixe", "montant": 2520, "condition": "Solar Keymark + Surface ≥ 2m² + Installateur certifié + Fraction solaire ≥ 60%"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 1680, "condition": "Solar Keymark + Surface ≥ 2m² + Installateur certifié + Fraction solaire ≥ 60%"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 1260, "condition": "Solar Keymark + Surface ≥ 2m² + Installateur certifié + Fraction solaire ≥ 60%"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 840, "condition": "Solar Keymark + Surface ≥ 2m² + Installateur certifié + Fraction solaire ≥ 60%"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 420, "condition": "Solar Keymark + Surface ≥ 2m² + Installateur certifié + Fraction solaire ≥ 60%"}
  }'),
  condition: "Installateur certifié rescert.be (art. 3, § 2, 2° arrêté 27/06/2013). Capteurs Solar Keymark NBN EN 12975 + surface optique ≥ 2m² (solarkeymark.dk). Fraction solaire ≥ 60%. Orientation sud-est-ouest. Système comptage: débitmètre + 2 thermomètres + compteur énergie thermique + compteur eau sanitaire. Calorifugeage annexe C4 arrêté 15/05/2014. Permis urbanisme si nécessaire.",
  conseil: "Orientation optimale 45° sud. Vérifier règles urbanisme pour capteurs sol.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos capteurs solaires + Offre-type complétée/signée + Certificats Solar Keymark",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r1": {"type": "montant_fixe", "montant": 960, "condition": "Liste éligible energie.wallonie.be - Foyer fermé - Installateur certifié (2026)"},
    "wallonie_r2": {"type": "montant_fixe", "montant": 640, "condition": "Liste éligible energie.wallonie.be - Foyer fermé - Installateur certifié (2026)"},
    "wallonie_r3": {"type": "montant_fixe", "montant": 480, "condition": "Liste éligible energie.wallonie.be - Foyer fermé - Installateur certifié (2026)"},
    "wallonie_r4": {"type": "montant_fixe", "montant": 320, "condition": "Liste éligible energie.wallonie.be - Foyer fermé - Installateur certifié (2026)"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 160, "condition": "Liste éligible energie.wallonie.be - Foyer fermé - Installateur certifié (2026)"}
  }'),
  condition: "Poêle repris liste éligible energie.wallonie.be (sinon mail primeshabitation@spw.wallonie.be + rapport test fabricant). OBLIGATOIRE: foyer fermé. EXCLUSION: feux ouverts et appareils mixtes (ouvert/fermé). Installateur certifié rescert.be (dès 01/01/2026) + BCE + accès profession.",
  conseil: "Installation conduit conforme. Ventilation suffisante. Vérifier éligibilité sur energie.wallonie.be.",
  document: "Factures détaillées + Annexe technique 6 complétée/signée + Photos démonstrant effectivité + Si hors liste: rapport test NBN EN 14785/13240/13229/12809/15250/12815/16510 selon type poêle",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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

puts "✅ Primes Chauffage Wallonie créées avec succès (5 primes)"
