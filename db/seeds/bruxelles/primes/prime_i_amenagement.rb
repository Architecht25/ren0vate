# =====================================================
# PRIME I : Aménagement intérieur
# =====================================================

puts "🏠 Création des primes I - Aménagement intérieur..."

Prime.find_or_initialize_by(slug: "bruxelles_escaliers").update!(
  titre: "I1 - Escaliers intérieurs - Bruxelles",
  ordre_affichage: 33,
  icon_name: "ladder",
  unite: "€/marche",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_unite", "montant_unite": 30, "condition": "Placement/remplacement escaliers intérieurs - Forfait par marche"},
    "bruxelles_cat2": {"type": "montant_unite", "montant_unite": 50, "condition": "Placement/remplacement escaliers intérieurs - Forfait par marche"},
    "bruxelles_cat3": {"type": "montant_unite", "montant_unite": 80, "condition": "Placement/remplacement escaliers intérieurs - Forfait par marche"}
  }'),
  condition: "LOGEMENTS uniquement (80% min. copropriétés). Bâtiments ≥10 ans. Placement/remplacement escaliers intérieurs en bois, béton ou métal. EXCLUS: escaliers escamotables. Propriétaire occupant avec restrictions vente/donation 5 ans si prime >30k€.",
  conseil: "Améliore sécurité et accessibilité logement. Inclut revêtements, paliers, mains courantes, balustres, trémies, parapets massifs. Forfait calculé par marche pour faciliter estimation. Matériaux durables recommandés.",
  document: "Attestation entrepreneur (général + technique I1) + Factures détaillées avec nombre marches précis, matériaux utilisés + Preuves paiement (>3000€: extraits bancaires) + Documents propriété/copropriété",
  specifique: "Bruxelles - Renolution I1",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre de marches",
    "bruxelles_cat2": "Nombre de marches",
    "bruxelles_cat3": "Nombre de marches"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/escaliers_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_emplacement_velo").update!(
  titre: "I2 - Emplacements vélo - Bruxelles",
  ordre_affichage: 34,
  icon_name: "bicycle",
  unite: "€/emplacement (max 2/logement)",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_unite", "montant_unite": 80, "limite": 2, "condition": "Aménagement emplacements vélo - Forfait 80€/emplacement, max 2/logement"},
    "bruxelles_cat2": {"type": "montant_unite", "montant_unite": 80, "limite": 2, "condition": "Aménagement emplacements vélo - Forfait 80€/emplacement, max 2/logement"},
    "bruxelles_cat3": {"type": "montant_unite", "montant_unite": 80, "limite": 2, "condition": "Aménagement emplacements vélo - Forfait 80€/emplacement, max 2/logement"}
  }'),
  condition: "LOGEMENTS uniquement (80% min. copropriétés). Bâtiments ≥10 ans. Aménagement emplacements vélo sécurisés. MAX 2 emplacements/logement. Forfait unique 80€ toutes catégories. Propriétaire occupant avec restrictions vente/donation 5 ans si prime >30k€.",
  conseil: "Encourage mobilité douce et répond obligations urbanistiques. Forfait simple: 80€/emplacement, maximum 2 par logement. Inclut dispositifs fixation, arceaux, supports, parois. Améliore valeur immobilière et attractivité logement.",
  document: "Attestation entrepreneur (général) + Factures détaillées avec nombre précis emplacements, description aménagements + Preuves paiement (>3000€: extraits bancaires) + Documents propriété/copropriété",
  specifique: "Bruxelles - Renolution I2",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre emplacements vélo (max 2/logement)",
    "bruxelles_cat2": "Nombre emplacements vélo (max 2/logement)",
    "bruxelles_cat3": "Nombre emplacements vélo (max 2/logement)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/emplacement_velo_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_protection_incendie").update!(
  titre: "I3 - Protection incendie (copropriétés) - Bruxelles",
  ordre_affichage: 35,
  icon_name: "shield-alert",
  unite: "% du coût HTVA",
  type_de_valeur: "pourcentage",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 20,
      "condition": "Compartimentage logement/parties communes - 20% coûts HTVA - Avis SIAMU obligatoire"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 20,
      "condition": "Compartimentage logement/parties communes - 20% coûts HTVA - Avis SIAMU obligatoire"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 20,
      "condition": "Compartimentage logement/parties communes - 20% coûts HTVA - Avis SIAMU obligatoire"
    }
  }'),
  condition: "Pose ou mise à niveau d'éléments passifs ou actifs de protection incendie (portes coupe-feu, détecteurs, cloisons, revêtements RF, etc.)",
  conseil: "Sécurité incendie copropriétés. 20% coûts HTVA toutes catégories. Inclut: compartimentage, intervention plafonds, portes RF. Matériaux conformes normes REI. Document essentiel: avis SIAMU à fournir obligatoirement.",
  document: "Attestation entrepreneur (général + technique I3) + OBLIGATOIRE: Avis prévention incendie SIAMU + Factures détaillées avec description matériaux RF + Preuves paiement (>3000€: extraits bancaires) + Documents copropriété",
  specifique: "Bruxelles - Renolution I3",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant HTVA travaux éligibles",
    "bruxelles_cat2": "Montant HTVA travaux éligibles",
    "bruxelles_cat3": "Montant HTVA travaux éligibles"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/protection_incendie.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_amenagement_pmr").update!(
  titre: "I4 - Aménagements personnes handicapées - Bruxelles",
  ordre_affichage: 36,
  icon_name: "universal-access",
  unite: "€ forfaitaire",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 7500, "condition": "Adaptation logement/bâtiment personnes handicapées - Forfait 7.500€ logement ou bâtiment"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 7500, "condition": "Adaptation logement/bâtiment personnes handicapées - Forfait 7.500€ logement ou bâtiment"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 7500, "condition": "Adaptation logement/bâtiment personnes handicapées - Forfait 7.500€ logement ou bâtiment"}
  }'),
  condition: "LOGEMENTS uniquement (80% min. copropriétés). Bâtiments ≥10 ans. Adaptation parties privatives/communes pour personnes handicapées. 7.500€/logement (privatif) ou 7.500€/bâtiment (communs). Propriétaire occupant avec restrictions vente/donation 5 ans si prime >30k€. OBLIGATOIRE: attestation reconnaissance handicap.",
  conseil: "Accessibilité et adaptation logements. Forfait identique toutes catégories: 7.500€. Travaux selon cahier prescriptions techniques accessibilité. Inclut: adaptation logement, équipements spécifiques, voies accès, portes, sanitaires. Document essentiel: attestation handicap obligatoire.",
  document: "Attestation entrepreneur (général + technique I4) + OBLIGATOIRE: Attestation reconnaissance/allocation personnes handicapées + Factures détaillées travaux adaptation + Preuves paiement (>3000€: extraits bancaires) + Documents propriété/copropriété",
  specifique: "Bruxelles - Renolution I4",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Forfait 7.500€ - Préciser si privatif ou commun",
    "bruxelles_cat2": "Forfait 7.500€ - Préciser si privatif ou commun",
    "bruxelles_cat3": "Forfait 7.500€ - Préciser si privatif ou commun"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/amenagement_pmr_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

puts "✅ Primes I (Aménagement intérieur) créées avec succès"
