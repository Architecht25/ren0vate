# =====================================================
# PRIME B : Installations de chantier
# =====================================================

puts "🏗️  Création des primes B - Installations de chantier..."

Prime.find_or_initialize_by(slug: "bruxelles_protection_echafaudages").update!(
  titre: "B1 - Protection et échafaudage - Bruxelles",
  ordre_affichage: 9,
  icon_name: "ladder",
  unite: "€/m²",
  type_de_valeur: "dynamique",
  eligible_categories: ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"],
  valeurs_par_categorie: JSON.parse('{
    "bruxelles_cat1": {"type": "montant_m2", "montant_m2": 20, "condition": "20€/m² échafaudage - Cat. I (défaut)"},
    "bruxelles_cat2": {"type": "montant_m2", "montant_m2": 30, "condition": "30€/m² échafaudage - Cat. II (revenus moyens)"},
    "bruxelles_cat3": {"type": "montant_m2", "montant_m2": 40, "condition": "40€/m² échafaudage - Cat. III (faibles revenus)"}
  }'),
  condition: "Tous publics (particuliers et professionnels). Bâtiments résidentiels construits au moins 10 ans avant demande. Échafaudage nécessaire pour travaux Toiture (E) ou Façades (F) sauf isolation acoustique murs. Entreprise professionnelle BCE avec TVA et accès réglementé. Échafaudage suspendu conforme NBN EN 12810 et NBN EN 12811.",
  conseil: "Prime B1 obligatoirement liée à prime Toiture (E) ou Façades (F). Calcul par m² d\'échafaudage selon catégorie revenus (20€-30€-40€). Une seule fois/10 ans par emplacement et type travaux. Minimum 250€ par adresse. Délai traitement 90 jours max. Demande via IRISbox après travaux (max 12 mois après facture solde).",
  document: "Attestation entrepreneur + attestation technique Protection/échafaudage + factures détaillées (type protection, surface concernée) + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires si cumul primes (titre propriété, extrait cadastral, etc.).",
  specifique: "Bruxelles - Renolution B1 - Soutien échafaudage travaux toiture/façades sécurisés",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Surface échafaudage en m² (20€/m²)",
    "bruxelles_cat2": "Surface échafaudage en m² (30€/m²)",
    "bruxelles_cat3": "Surface échafaudage en m² (40€/m²)"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/echafaudage_bruxelles.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

puts "✅ Primes B (Installations chantier) créées avec succès"
