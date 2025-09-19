# =====================================================
# PRIMES WALLONIE - SOLS
# =====================================================
# Module pour les primes de sols (4 primes)
# =====================================================

puts "🏗️ Création des primes Sols Wallonie..."

# === SOLS ===

Prime.find_or_initialize_by(slug: "wallonie_remplacement_supports_circulation").update!(
  titre: "Remplacement des supports des aires de circulation - Wallonie",
  ordre_affichage: 14,
  icon_name: "layer-group",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["wallonie_r1", "wallonie_r2", "wallonie_r3", "wallonie_r4", "wallonie_r5"],
  valeurs_par_categorie: JSON.parse('{
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 12, "condition": "Travaux salubrité liés isolation sols"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 8, "condition": "Travaux salubrité liés isolation sols"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 6, "condition": "Travaux salubrité liés isolation sols"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 4, "condition": "Travaux salubrité liés isolation sols"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 2, "condition": "Travaux salubrité liés isolation sols"}
  }'),
  condition: "Travaux liés obligatoires sur même paroi que isolation sols. Remplacement supports (gîtage, hourdis), aires circulation, sous-couches, plinthes induit par travaux. Même demande de prime que isolation.",
  conseil: "Obligatoire si mentionné dans rapport d'audit. Coordonner avec isolation sols. Diagnostic structure préalable recommandé.",
  document: "Factures détaillées + Photos avant/pendant/après + Même demande que isolation sols + Plans techniques",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 36, "condition": "R ≥ 3,50 m²K/W - Entrepreneur BCE"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 24, "condition": "R ≥ 3,50 m²K/W - Entrepreneur BCE"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 18, "condition": "R ≥ 3,50 m²K/W - Entrepreneur BCE"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 12, "condition": "R ≥ 3,50 m²K/W - Entrepreneur BCE"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 6, "condition": "R ≥ 3,50 m²K/W - Entrepreneur BCE"}
  }'),
  condition: "Entrepreneur BCE enregistré. Sol contact extérieur/espace non chauffé à l'abri du gel ou non/sol. R ≥ 3,50 m²K/W. Multicouches acceptées. Lambda certifié ATG/ETA/CE ou base EPBD. Paroi existante au jour audit. Travaux liés obligatoires sur même paroi.",
  conseil: "Isolation par dessous privilégiée si cave accessible. Coordonner avec remplacement supports si nécessaire.",
  document: "Factures détaillées + Annexe technique 3 complétée/signée + Photos avant/pendant/après + Certificats lambda isolants",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 48, "condition": "R ≥ 3,50 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 32, "condition": "R ≥ 3,50 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 24, "condition": "R ≥ 3,50 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 16, "condition": "R ≥ 3,50 m²K/W + biosourcé - Entrepreneur BCE"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 8, "condition": "R ≥ 3,50 m²K/W + biosourcé - Entrepreneur BCE"}
  }'),
  condition: "Entrepreneur BCE enregistré. Matériau biosourcé certifié. Sol contact extérieur/espace non chauffé à l'abri du gel ou non/sol. R ≥ 3,50 m²K/W. Multicouches acceptées. Lambda certifié ATG/ETA/CE ou base EPBD. Paroi existante au jour audit. Travaux liés obligatoires sur même paroi.",
  conseil: "Prime majorée pour matériaux écologiques. Coordonner avec remplacement supports si nécessaire.",
  document: "Factures détaillées + Certificat biosourcé + Annexe technique 3 complétée/signée + Photos avant/pendant/après + Certificats lambda isolants",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  statut_compatible: "12 mois à partir de la date de facture de solde",
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

puts "✅ Primes Sols Wallonie créées avec succès (4 primes)"
