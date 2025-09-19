# =====================================================
# PRIME K : Sanitaires
# PRIME L : Électricité & gaz
# PRIME M : Ventilation
# PRIME Z : Bonus
# =====================================================

puts "🚿 Création des primes K, L, M, Z..."

# =====================================================
# PRIME K : Sanitaires
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_appareil_sanitaire").update!(
  titre: "K1 - Appareils et installation sanitaires - Bruxelles",
  ordre_affichage: 44,
  icon_name: "droplet-half",
  unite: "€/appareil",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_unite", "montant_unite": 200, "condition": "200€ par appareil sanitaire (max 5 par logement)"},
    "bruxelles_cat2": {"type": "montant_unite", "montant_unite": 340, "condition": "340€ par appareil sanitaire (max 5 par logement)"},
    "bruxelles_cat3": {"type": "montant_unite", "montant_unite": 540, "condition": "540€ par appareil sanitaire (max 5 par logement)"}
  }'),
  condition: "Logements ou bâtiments affectés au logement construits depuis au moins 10 ans. Propriétaire occupant (inscription registre population 5 ans si prime >30.000€) ou propriétaire non occupant avec contrat AIS 9 ans minimum. Copropriété forcée: bâtiment affecté logement à 80% minimum. Maximum 5 appareils par logement.",
  conseil: "Installation d'appareils sanitaires et raccordement: lavabo, lave-mains, douche, bain, évier, WC, bidet. Bonus réemploi disponible: +70€/appareil (max 5) si appareils de réemploi mentionnés expressément sur facture.",
  document: "Attestation entrepreneur (informations générales + volet technique K1). Factures détaillées (description précise appareils, accessoires, circuits arrivée/évacuation). Si bonus réemploi: mention expresse achat magasin revente. Preuves paiement.",
  specifique: "Bruxelles - Renolution - Ref: K1. EXCLUSIVEMENT résidentiel. Propriétaire occupant ou AIS. Copropriété forcée acceptée si 80% logement. Bonus réemploi +70€/appareil toutes catégories. Maximum 5 appareils/logement. Installation par entreprise BCE avec accès réglementé.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Nombre appareils × 200€ (+70€ réemploi)",
    "bruxelles_cat2": "Nombre appareils × 340€ (+70€ réemploi)",
    "bruxelles_cat3": "Nombre appareils × 540€ (+70€ réemploi)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/sanitaire_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME L : Électricité & gaz
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_mise_normes_electricite_gaz").update!(
  titre: "L1 - Conformité de l'installation électrique - Bruxelles",
  ordre_affichage: 45,
  icon_name: "lightning",
  unite: "% des coûts éligibles HTVA",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "pourcentage", "pourcentage": 30, "condition": "30% des coûts éligibles HTVA (mise en conformité électrique)"},
    "bruxelles_cat2": {"type": "pourcentage", "pourcentage": 50, "condition": "50% des coûts éligibles HTVA (mise en conformité électrique)"},
    "bruxelles_cat3": {"type": "pourcentage", "pourcentage": 70, "condition": "70% des coûts éligibles HTVA (mise en conformité électrique)"}
  }'),
  condition: "Logements ou bâtiments affectés au logement construits depuis au moins 10 ans. Propriétaire occupant (inscription registre + engagement 5 ans si prime >30.000€) ou propriétaire non occupant avec contrat AIS 9 ans. Copropriété forcée: bâtiment affecté logement à 80%. Rapport contrôle organisme agréé obligatoire. Exclusion installations internet.",
  conseil: "Mise en conformité installation électrique espace habitable: tableau principal/divisionnaires, prises, interrupteurs, points lumineux (hors appareils éclairage), rénovation plafonnages/murs liés aux travaux électriques. Rapport contrôle totalité installation requis.",
  document: "Attestation entrepreneur (informations générales). Rapport contrôle totalité installation par organisme contrôle agréé OBLIGATOIRE. Factures détaillées (tableaux électriques, prises, interrupteurs, points lumineux, travaux plafonnages/murs liés). Preuves paiement.",
  specifique: "Bruxelles - Renolution - Ref: L1. EXCLUSIVEMENT résidentiel. Propriétaire occupant, AIS ou copropriété forcée (80% logement). Plafond: 50.000€ logement individuel / 200.000€ bâtiment entier. Rapport organisme agréé OBLIGATOIRE. Installation par entreprise BCE électrotechnique.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Coût travaux × 30% (HTVA)",
    "bruxelles_cat2": "Coût travaux × 50% (HTVA)",
    "bruxelles_cat3": "Coût travaux × 70% (HTVA)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/electricite_gaz_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME M : Ventilation
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_ventilation_systeme_c").update!(
  titre: "M1 - Ventilation mécanique contrôlée: Système C - Bruxelles",
  ordre_affichage: 46,
  icon_name: "wind",
  unite: "€/logement individuel",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 1550, "condition": "1.550€ par logement individuel (VMC simple flux centralisé)"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 1950, "condition": "1.950€ par logement individuel (VMC simple flux centralisé)"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 2230, "condition": "2.230€ par logement individuel (VMC simple flux centralisé)"}
  }'),
  condition: "Bâtiments résidentiels uniquement, construits depuis au moins 10 ans. VMC simple flux centralisé avec régulation débits permanents extraction. Système conforme PEB (annexe XIX NBN D50-001) et EPDB. Système complet: ouvertures alimentation locaux secs + évacuation locaux humides + transferts. Extraction centralisée. Interdiction chauffage électrique et climatisation électrique. Débits permanents obligatoires.",
  conseil: "Si vous avez rénové votre logement qui devient plus étanche, un système de ventilation avec évacuation mécanique de l'air devient essentiel pour assurer le confort intérieur et évacuer l'humidité.",
  document: "Attestation entrepreneur (informations générales + volet technique M1). Factures détaillées (marque, modèle ventilation, type régulation, ensemble système C, percements gaines). Mesures débits sortie/entrée bouches + réglage installation obligatoires. Preuves paiement.",
  specifique: "Bruxelles - Renolution - Ref: M1. EXCLUSIVEMENT résidentiel. Bonus plusieurs travaux (Z10): +10% (cat I&II), +20% (cat III) si ≥3 primes combinées. Système EPDB ou calcul débits requis. Mesures et réglage installateur obligatoires. Installation par entreprise BCE avec accès réglementé.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "1.550€ par logement (+10% si Z10)",
    "bruxelles_cat2": "1.950€ par logement (+10% si Z10)",
    "bruxelles_cat3": "2.230€ par logement (+20% si Z10)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/ventilation_c_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_ventilation_systeme_d").update!(
  titre: "M2 - Ventilation mécanique contrôlée: Système D - Bruxelles",
  ordre_affichage: 47,
  icon_name: "arrow-repeat",
  unite: "€/logement ou % coûts",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_fixe", "montant": 3000, "condition": "Résidentiel: 3.000€/logement - Non résidentiel: 25% échangeur+régulation"},
    "bruxelles_cat2": {"type": "montant_fixe", "montant": 3750, "condition": "Résidentiel: 3.750€/logement - Non résidentiel: 25% échangeur+régulation"},
    "bruxelles_cat3": {"type": "montant_fixe", "montant": 4300, "condition": "Résidentiel: 4.300€/logement - Non résidentiel: 25% échangeur+régulation"}
  }'),
  condition: "Bâtiments résidentiels et non résidentiels construits depuis au moins 10 ans. VMC double flux avec récupération chaleur et régulation débits permanents. Système conforme PEB (annexe XIX NBN D50-001 résidentiel / annexe XX NBN EN 13779 non résidentiel) et EPDB. Échangeur rendement minimum 80%. Système complet centralisé. Débits permanents résidentiel / régulation adaptée non résidentiel.",
  conseil: "Système double-flux très économe en énergie qui transfère la chaleur de l'air sortant à l'air entrant, assurant qualité d'air et confort respiratoire optimaux lors de la rénovation.",
  document: "Attestation entrepreneur (informations générales + volet technique M2). Factures détaillées (marque, modèle ventilation, type régulation, échangeur thermique, ensemble système D, percements). Mesures débits + réglage obligatoires. Non résidentiel: surcoût échangeur ou forfait 30%. Preuves paiement.",
  specifique: "Bruxelles - Renolution - Ref: M2. Résidentiel ET non résidentiel. Bonus plusieurs travaux (Z10): +10% (cat I&II), +20% (cat III) si ≥3 primes. Échangeur 80% minimum. Système EPDB ou calcul débits. Régulation avancée non résidentiel (CO2, COV, présence, etc.). Installation par entreprise BCE.",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Résidentiel: 3.000€ - Non résidentiel: 25%",
    "bruxelles_cat2": "Résidentiel: 3.750€ - Non résidentiel: 25%",
    "bruxelles_cat3": "Résidentiel: 4.300€ - Non résidentiel: 25%"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/vmc_double_flux_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

# =====================================================
# PRIME Z : Bonus
# =====================================================

Prime.find_or_initialize_by(slug: "bruxelles_bonus_z10").update!(
  titre: "Bonus Z10 – Plusieurs travaux combinés - Bruxelles",
  ordre_affichage: 55,
  icon_name: "layers",
  unite: "%",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "pourcentage", "pourcentage": 10, "condition": "Au moins 3 types de travaux soumis"},
    "bruxelles_cat2": {"type": "pourcentage", "pourcentage": 10, "condition": "Au moins 3 types de travaux soumis"},
    "bruxelles_cat3": {"type": "pourcentage", "pourcentage": 20, "condition": "Au moins 3 types de travaux soumis"}
  }'),
  condition: "Regroupement de trois travaux ou plus dans la même demande",
  conseil: "Réunissez vos travaux pour maximiser la prime globale",
  document: "Factures pour chaque type de travaux + récapitulatif",
  specifique: "Bruxelles - Renolution",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Pourcentage de majoration appliqué",
    "bruxelles_cat2": "Pourcentage de majoration appliqué",
    "bruxelles_cat3": "Pourcentage de majoration appliqué"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/bonus_z10.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

puts "✅ Primes K, L, M, Z créées avec succès"
