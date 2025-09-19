# =====================================================
# PRIME G : Portes & fenêtres
# =====================================================

puts "🪟 Création des primes G - Portes & fenêtres..."

Prime.find_or_initialize_by(slug: "bruxelles_remplacement_fenetres_bois").update!(
  titre: "G1 - Placement et remplacement de portes et fenêtres (bois) - Bruxelles",
  ordre_affichage: 27,
  icon_name: "window",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 100, "condition": "Portes et fenêtres en bois - Ug ≤ 1,1 W/m²K, Uw ≤ 1,5 W/m²K (fenêtres), Ud ≤ 2,0 W/m²K (portes)"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 120, "condition": "Portes et fenêtres en bois - Ug ≤ 1,1 W/m²K, Uw ≤ 1,5 W/m²K (fenêtres), Ud ≤ 2,0 W/m²K (portes)"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 140, "condition": "Portes et fenêtres en bois - Ug ≤ 1,1 W/m²K, Uw ≤ 1,5 W/m²K (fenêtres), Ud ≤ 2,0 W/m²K (portes)"}
  }'),
  condition: "Placement/remplacement portes d\'entrée et fenêtres en bois. Bâtiments ≥10 ans. Seules fenêtres verticales éligibles. Exigences techniques: Ug ≤ 1,1 W/m²K, Uw ≤ 1,5 W/m²K (fenêtres), Ud ≤ 2,0 W/m²K (portes).",
  conseil: "Matériau écologique sans conditions. BONUS: +100€/m² si bois FSC/PEFC ou réemploi. +35€/m² si vitrage acoustique (Rw+Ctr ≥34 dB) ou porte acoustique (Rw+Ctr ≥30 dB). Bonus Z10: +10%/20% si ≥3 primes combinées.",
  document: "Attestation entrepreneur (général + technique) + Factures détaillées avec surface, matériaux, valeurs Ug/Uw/Ud + Preuves paiement (>3000€: extraits bancaires) + Si FSC/PEFC: certification sur facture + Si réemploi: preuve achat + Si acoustique: valeurs Rw+Ctr sur facture",
  specifique: "Bruxelles - Renolution G1",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface portes/fenêtres en m²",
    "bruxelles_cat2": "Surface portes/fenêtres en m²",
    "bruxelles_cat3": "Surface portes/fenêtres en m²"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/fenetres_bois_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_remplacement_fenetres_pvc_alu").update!(
  titre: "G1 - Placement et remplacement de portes et fenêtres (PVC/métal) - Bruxelles",
  ordre_affichage: 28,
  icon_name: "window-desktop",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 40, "condition": "Portes et fenêtres PVC/métal - Remplacement à l\'identique uniquement ou avec autres primes"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 50, "condition": "Portes et fenêtres PVC/métal - Remplacement à l\'identique uniquement ou avec autres primes"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 55, "condition": "Portes et fenêtres PVC/métal - Remplacement à l\'identique uniquement ou avec autres primes"}
  }'),
  condition: "RESTRICTIONS: PVC/métal éligibles UNIQUEMENT si remplacement à l\'identique (attestation entrepreneur obligatoire) OU si combiné avec primes A2,A4,C1,C2,C3,C4,D1,D2,E1,E4,F4,F5,F6,G3,H2,I1,I2,I3,K1,L1 (permis urbanisme requis). Exigences: Ug ≤ 1,1 W/m²K, Uw ≤ 1,5 W/m²K (fenêtres), Ud ≤ 2,0 W/m²K (portes).",
  conseil: "Matériaux PVC/métal sous conditions strictes. BONUS: +35€/m² si vitrage acoustique (Rw+Ctr ≥34 dB) ou porte acoustique (Rw+Ctr ≥30 dB). Bonus Z10: +10%/20% si ≥3 primes combinées. Privilégier le bois si possible.",
  document: "Attestation entrepreneur (général + technique) + Factures détaillées + Preuves paiement + OBLIGATOIRE: attestation remplacement à l\'identique OU permis urbanisme/PV copropriété si combiné avec autres primes + Si acoustique: valeurs Rw+Ctr sur facture",
  specifique: "Bruxelles - Renolution G1",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface portes/fenêtres en m²",
    "bruxelles_cat2": "Surface portes/fenêtres en m²",
    "bruxelles_cat3": "Surface portes/fenêtres en m²"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/fenetres_pvc_alu_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_reparation_fenetres").update!(
  titre: "G2 - Réparation et adaptation de fenêtres - Bruxelles",
  ordre_affichage: 29,
  icon_name: "tools",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 130, "condition": "Réparation châssis existants + placement double/triple vitrage - Ug ≤ 1,2 W/m²K"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 220, "condition": "Réparation châssis existants + placement double/triple vitrage - Ug ≤ 1,2 W/m²K"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 260, "condition": "Réparation châssis existants + placement double/triple vitrage - Ug ≤ 1,2 W/m²K"}
  }'),
  condition: "Réparation/adaptation châssis existants (SAUF PVC) + placement obligatoire double/triple vitrage. Fenêtres verticales uniquement. Bâtiments ≥10 ans. Exigence technique: Ug ≤ 1,2 W/m²K.",
  conseil: "Alternative économique au remplacement pour châssis de qualité. Conserve le patrimoine architectural. BONUS: +35€/m² si vitrage acoustique (Rw+Ctr ≥34 dB) - logements uniquement. Bonus Z10: +10%/20% si ≥3 primes combinées (E3,F1,G1,G2,H1,J4,M1,M2).",
  document: "Attestation entrepreneur (général + technique spécifique G2) + Factures détaillées avec surface vitrages, valeur Ug, type matériaux + Preuves paiement (>3000€: extraits bancaires) + Si acoustique: valeur Rw+Ctr sur facture",
  specifique: "Bruxelles - Renolution G2",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface fenêtres réparées en m²",
    "bruxelles_cat2": "Surface fenêtres réparées en m²",
    "bruxelles_cat3": "Surface fenêtres réparées en m²"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/reparation_fenetres_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_reparation_portes").update!(
  titre: "G3 - Réparation de portes extérieures - Bruxelles",
  ordre_affichage: 30,
  icon_name: "door-closed",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 90, "condition": "Réparation portes extérieures façade en bois ou métal"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 150, "condition": "Réparation portes extérieures façade en bois ou métal"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 180, "condition": "Réparation portes extérieures façade en bois ou métal"}
  }'),
  condition: "Réparation portes extérieures façade en bois ou métal. LOGEMENTS uniquement (80% min. pour copropriétés). Bâtiments ≥10 ans. Propriétaire occupant avec restrictions vente/donation 5 ans si prime >30k€.",
  conseil: "Conservation patrimoine architectural. BONUS acoustique: +35€/m² pour portes solides/lourdes avec amélioration propriétés acoustiques. Bonus Z10: +10%/20% si ≥3 primes (E3,F1,G1,G2,G3,H1,J4,M1,M2).",
  document: "Attestation entrepreneur (général) + Factures détaillées avec description travaux + Preuves paiement (>3000€: extraits bancaires) + Documents propriété/copropriété + Si revenus autres que cat.I: justificatifs",
  specifique: "Bruxelles - Renolution G3",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface portes réparées en m²",
    "bruxelles_cat2": "Surface portes réparées en m²",
    "bruxelles_cat3": "Surface portes réparées en m²"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/reparation_portes_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

puts "✅ Primes G (Portes & fenêtres) créées avec succès"
