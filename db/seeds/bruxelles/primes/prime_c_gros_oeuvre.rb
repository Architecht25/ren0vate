# =====================================================
# PRIME C : Gros-œuvre & gestion de l'eau
# =====================================================

puts "🔧 Création des primes C - Gros-œuvre & gestion de l'eau..."

Prime.find_or_initialize_by(slug: "bruxelles_structure_portante").update!(
  titre: "C1 - Structures portantes - Bruxelles",
  ordre_affichage: 8,
  icon_name: "columns",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "pourcentage",
      "pourcentage": 30,
      "condition": "30% des coûts éligibles HTVA - Cat. I (défaut)"
    },
    "bruxelles_cat2": {
      "type": "pourcentage",
      "pourcentage": 50,
      "condition": "50% des coûts éligibles HTVA - Cat. II (revenus moyens)"
    },
    "bruxelles_cat3": {
      "type": "pourcentage",
      "pourcentage": 70,
      "condition": "70% des coûts éligibles HTVA - Cat. III (faibles revenus)"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Structure dans surface habitable uniquement. Entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime C1 = 30%-50%-70% coûts éligibles HTVA selon catégorie revenus. Travaux stabilité immeuble : fondations, éléments structurels (métal/bois/béton), planchers, maçonneries portantes/soutènement, voutes/voussettes, ouverture/fermeture baies murs porteurs, dalles béton. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse.",
  document: "Attestation entrepreneur + attestation technique Structures portantes + factures détaillées libellées au nom du demandeur + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  specifique: "Bruxelles - Renolution C1 - Travaux stabilité et renforcement structures portantes",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant coûts éligibles HTVA (€) - 30%",
    "bruxelles_cat2": "Montant coûts éligibles HTVA (€) - 50%",
    "bruxelles_cat3": "Montant coûts éligibles HTVA (€) - 70%"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/structure_portante.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_gestion_egouts").update!(
  titre: "C2 - Égouts - Bruxelles",
  ordre_affichage: 9,
  icon_name: "droplet",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {
      "type": "grille_variable",
      "grille": {
        "égout": 25,
        "chambre de visite": 80,
        "avaloir": 25,
        "chambre de disconnection": 165
      },
      "condition": "Cat. I (défaut) - Tarifs par élément évacuation eaux usées"
    },
    "bruxelles_cat2": {
      "type": "grille_variable",
      "grille": {
        "égout": 45,
        "chambre de visite": 130,
        "avaloir": 45,
        "chambre de disconnection": 275
      },
      "condition": "Cat. II (revenus moyens) - Tarifs par élément évacuation eaux usées"
    },
    "bruxelles_cat3": {
      "type": "grille_variable",
      "grille": {
        "égout": 70,
        "chambre de visite": 210,
        "avaloir": 70,
        "chambre de disconnection": 440
      },
      "condition": "Cat. III (faibles revenus) - Tarifs par élément évacuation eaux usées"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Conduites >90mm sous emprise bâtiment uniquement. Entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime C2 évacuation eaux usées. Tarifs : égout (25-45-70€/m), chambre visite (80-130-210€/pièce), avaloir (25-45-70€/pièce), chambre disconnection (165-275-440€/pièce). Conduites >90mm intérieures enterrées sous emprise bâtiment. Chemisage autorisé. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse.",
  document: "Attestation entrepreneur + attestation technique Égouts + factures détaillées (quantités chambres visite/avaloirs/disconnection et mètres égouts) + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  specifique: "Bruxelles - Renolution C2 - Travaux évacuation eaux usées sous emprise bâtiment",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Quantités par type : mètres égouts, nb chambres/avaloirs/disconnection",
    "bruxelles_cat2": "Quantités par type : mètres égouts, nb chambres/avaloirs/disconnection",
    "bruxelles_cat3": "Quantités par type : mètres égouts, nb chambres/avaloirs/disconnection"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/gestion_egouts.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_recuperation_eau_pluie").update!(
  titre: "C3 - Récupération d'eau de pluie - Bruxelles",
  ordre_affichage: 10,
  icon_name: "droplet",
  unite: "€",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 500, "condition": "500€/unité logement - Cat. I (défaut) + Bonus capacité tampon +100€ si ≥1000L"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 750, "condition": "750€/unité logement - Cat. II (revenus moyens) + Bonus capacité tampon +150€ si ≥1000L"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 1100, "condition": "1100€/unité logement - Cat. III (faibles revenus) + Bonus capacité tampon +200€ si ≥1000L"}
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Citerne ≥1000L/logement + pompe + raccordement ≥1 appareil sanitaire. Entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime C3 écologique = 500€-750€-1100€/unité logement selon catégorie revenus. Bonus capacité tampon +100€-150€-200€ si volume ≥1000L non conservé après pluie (protection inondations). Citerne ≥1000L/logement. Pompe + raccordement mini 1 appareil sanitaire (WC, lavabo, douche, etc.). Terrassement/maçonnerie inclus si nouvelle citerne. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€.",
  document: "Attestation entrepreneur + attestation technique Récupération eau pluie (C3) + factures détaillées (capacité citerne, pompe, raccordements) + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  specifique: "Bruxelles - Renolution C3 - Économies eau et protection inondations via récupération eau pluie",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre unités logement (500€ + bonus tampon 100€ si applicable)",
    "bruxelles_cat2": "Nombre unités logement (750€ + bonus tampon 150€ si applicable)",
    "bruxelles_cat3": "Nombre unités logement (1100€ + bonus tampon 200€ si applicable)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/eau_pluie_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_demolition_permeabilisation").update!(
  titre: "C4 - Démolition pour perméabiliser le sol - Bruxelles",
  ordre_affichage: 11,
  icon_name: "water",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 60, "condition": "60€/m² surface perméabilisée - Cat. I (défaut)"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 75, "condition": "75€/m² surface perméabilisée - Cat. II (revenus moyens)"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 90, "condition": "90€/m² surface perméabilisée - Cat. III (faibles revenus)"}
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Démolition annexes (dont dalle sol) supprimant surfaces imperméables. Entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime C4 écologique = 60€-75€-90€/m² surface perméabilisée selon catégorie revenus. Augmentation perméabilité par démolition annexes (suppression surfaces imperméables). Création noues, bassins en eau, puits infiltration. Calcul par m² surface récupérée. Bénéfices : gestion eaux pluie, biodiversité, qualité de vie urbaine. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse.",
  document: "Attestation entrepreneur + attestation technique Démolition perméabilisation sol + factures détaillées (surface perméabilisée précisée) + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  specifique: "Bruxelles - Renolution C4 - Perméabilisation sol biodiversité et gestion eaux pluviales",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface perméabilisée en m² (60€/m²)",
    "bruxelles_cat2": "Surface perméabilisée en m² (75€/m²)",
    "bruxelles_cat3": "Surface perméabilisée en m² (90€/m²)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/demolition_permeabilisation_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

puts "✅ Primes C (Gros-œuvre & gestion eau) créées avec succès"
