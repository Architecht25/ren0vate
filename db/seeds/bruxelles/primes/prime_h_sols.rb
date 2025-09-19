# =====================================================
# PRIME H : Sols & planchers
# =====================================================

puts "🏠 Création des primes H - Sols & planchers..."

Prime.find_or_initialize_by(slug: "bruxelles_isolation_thermique_sols").update!(
  titre: "H1 - Isolation thermique de sols et planchers - Bruxelles",
  ordre_affichage: 31,
  icon_name: "square",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 35, "condition": "Isolation sols/planchers - R≥2,00 m²K/W (dalles) ou R≥3,50 m²K/W (plafonds)"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 40, "condition": "Isolation sols/planchers - R≥2,00 m²K/W (dalles) ou R≥3,50 m²K/W (plafonds)"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 45, "condition": "Isolation sols/planchers - R≥2,00 m²K/W (dalles) ou R≥3,50 m²K/W (plafonds)"}
  }'),
  condition: "Isolation sols/dalles délimitant volume chauffé + planchers sur espaces non chauffés. Bâtiments ≥10 ans. Exigences: R≥2,00 m²K/W (dalles sol) ou R≥3,50 m²K/W (plafonds cave, planchers vide ventilé). Matériaux ATG/ETA/CE/EPBD.",
  conseil: "Réduit 10% déperditions thermiques, améliore confort. Privilégier isolation par le bas si possible. BONUS matériaux durables: +10€/m² si isolants naturels ≥85% renouvelables atteignant R requis. Bonus Z10: +10%/20% si ≥3 primes (E3,F1,G1,G2,H1,J4,M1,M2).",
  document: "Attestation entrepreneur (général + technique H1) + Factures détaillées avec type/marque/modèle isolant, surface, épaisseur, valeur R + Preuves paiement (>3000€: extraits bancaires) + Si bonus durable: justificatifs matériaux naturels",
  specifique: "Bruxelles - Renolution H1",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface sols/planchers isolés en m²",
    "bruxelles_cat2": "Surface sols/planchers isolés en m²",
    "bruxelles_cat3": "Surface sols/planchers isolés en m²"
  }'),
  statut_compatible: ["residentiel", "non_residentiel"],
  image: "images/isolation_sols_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_isolation_acoustique_sols").update!(
  titre: "H2 - Isolation acoustique de planchers et plafonds - Bruxelles",
  ordre_affichage: 32,
  icon_name: "volume-mute",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 30, "condition": "Isolation acoustique planchers/plafonds séparant logements - Systèmes techniques spécialisés"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 60, "condition": "Isolation acoustique planchers/plafonds séparant logements - Systèmes techniques spécialisés"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 90, "condition": "Isolation acoustique planchers/plafonds séparant logements - Systèmes techniques spécialisés"}
  }'),
  condition: "LOGEMENTS uniquement (80% min. copropriétés). Bâtiments ≥10 ans. Isolation acoustique planchers/plafonds séparant 2 logements. Propriétaire occupant avec restrictions vente/donation 5 ans si prime >30k€. Techniques: chapes flottantes, complexes isolants, faux-plafonds acoustiques.",
  conseil: "Améliore confort, santé et bien-être. BONUS matériaux durables: +10€/m² si isolants naturels ≥85% renouvelables (cellulose, liège, fibres végétales/animales). Systèmes spécialisés: chapes flottantes, lambourdes, alternance couches, faux-plafonds antivibratiles.",
  document: "Attestation entrepreneur (général + technique H2) + Factures détaillées avec type/marque/modèle isolant, surface, épaisseur, systèmes techniques + Preuves paiement (>3000€: extraits bancaires) + Documents propriété/copropriété + Si bonus durable: justificatifs matériaux naturels",
  specifique: "Bruxelles - Renolution H2",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface planchers/plafonds isolés en m²",
    "bruxelles_cat2": "Surface planchers/plafonds isolés en m²",
    "bruxelles_cat3": "Surface planchers/plafonds isolés en m²"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/isolation_acoustique_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

puts "✅ Primes H (Sols & planchers) créées avec succès"
