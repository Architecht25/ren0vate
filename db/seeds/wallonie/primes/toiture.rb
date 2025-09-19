# =====================================================
# PRIMES WALLONIE - TOITURE
# =====================================================
# Module pour les primes de toiture (5 primes)
# =====================================================

puts "🏠 Création des primes Toiture Wallonie..."

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
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r4": {"type": "montant_fixe", "montant": 80, "condition": "Remplacement système"},
    "wallonie_r5": {"type": "montant_fixe", "montant": 40, "condition": "Remplacement système"}
  }'),
  condition: "Remplacement du dispositif de collecte et d'évacuation des eaux pluviales.",
  conseil: "Dimensionnement selon surface toiture. Raccordement aux égouts.",
  document: "Factures + plan évacuation + photos installation",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
    "wallonie_r1": {"type": "montant_m2", "montant_m2": 120, "condition": "R ≥ 5,00 m²K/W"},
    "wallonie_r2": {"type": "montant_m2", "montant_m2": 80, "condition": "R ≥ 5,00 m²K/W"},
    "wallonie_r3": {"type": "montant_m2", "montant_m2": 60, "condition": "R ≥ 5,00 m²K/W"},
    "wallonie_r4": {"type": "montant_m2", "montant_m2": 40, "condition": "R ≥ 5,00 m²K/W"},
    "wallonie_r5": {"type": "montant_m2", "montant_m2": 20, "condition": "R ≥ 5,00 m²K/W"}
  }'),
  condition: "• Travaux réalisés par entrepreneur BCE enregistré\n• Isolation thermique du toit/combles en contact avec extérieur, espace non chauffé à l'abri du gel ou non à l'abri du gel, ou sol\n• Coefficient de résistance thermique R ≥ 5,00 m²K/W\n• Isolant placé en plusieurs couches : somme des résistances ≥ 5,00 m²K/W\n• Seuls matériaux de la demande comptabilisés (couche existante exclue)\n• Valeurs lambda (λ) certifiées par ATG, ETA, marquage CE ou base EPBD (www.epbd.be)\n• À défaut : valeurs Annexe B1 Arrêté 15/05/2014 ou norme NBN B 62-002\n• Paroi isolée existante au jour de visite auditeur",
  conseil: "Si audit mentionne 'travaux liés' sur même paroi, demande unique obligatoire. Travaux salubrité liés possibles : remplacement couverture, appropriation charpente, remplacement dispositifs collecte/évacuation eaux pluviales (hors stockage). Vérifier continuité isolation et étanchéité air.",
  document: "• Copie ensemble des factures (montants détaillés des éléments, liste travaux éligibles sur https://energie.wallonie.be)\n• Annexe technique 1 administration complétée, datée et signée par entrepreneur\n• Photos explicites avant, pendant et après travaux\n• Certificats matériaux isolants (ATG, ETA, marquage CE ou EPBD)\n• Attestation entrepreneur BCE",
  statut_compatible: "12 mois à partir de la date de facture de solde",
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
  statut_compatible: "12 mois à partir de la date de facture de solde",
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

puts "✅ Primes Toiture Wallonie créées avec succès (5 primes)"
