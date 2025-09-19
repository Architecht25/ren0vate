# =====================================================
# PRIME D : Salubrité
# =====================================================

puts "🏠 Création des primes D - Salubrité..."

Prime.find_or_initialize_by(slug: "bruxelles_traitement_humidite_sol").update!(
  titre: "D1 - Problème d'humidité - Bruxelles",
  ordre_affichage: 12,
  icon_name: "waves",
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
      "pourcentage": 80,
      "condition": "80% des coûts éligibles HTVA - Cat. III (faibles revenus)"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Techniques suppression humidité maçonneries (hors plafonnage/carrelage). Entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime D1 = 30%-50%-80% coûts éligibles HTVA selon catégorie revenus. Techniques suppression humidité maçonneries : injection produits hydrofuges, insertion membrane étanche, protection murs enterrés (cimentage, revêtement étanche, drainage), cuvelage. EXCLUS : plafonnage et carrelage. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€. Minimum 250€ par adresse.",
  document: "Attestation entrepreneur + attestation technique Problème humidité + factures détaillées libellées au nom du demandeur + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  specifique: "Bruxelles - Renolution D1 - Suppression humidité maçonneries techniques spécialisées",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant coûts éligibles HTVA (€) - 30%",
    "bruxelles_cat2": "Montant coûts éligibles HTVA (€) - 50%",
    "bruxelles_cat3": "Montant coûts éligibles HTVA (€) - 80%"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/humidite_sol.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

Prime.find_or_initialize_by(slug: "bruxelles_traitement_fongique_insectes").update!(
  titre: "D2 - Champignons, moisissures et insectes - Bruxelles",
  ordre_affichage: 13,
  icon_name: "bug",
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
      "pourcentage": 80,
      "condition": "80% des coûts éligibles HTVA - Cat. III (faibles revenus)"
    }
  }'),
  condition: "Propriétaires occupants (avec engagements si prime >30.000€), propriétaires non-occupants avec contrat AIS 9 ans, copropriétés forcées, AIS, syndics. Logements construits au moins 10 ans avant demande (80% affectation logement copropriétés). Travaux basés sur rapport laboratoire agréé obligatoire. Entreprise professionnelle BCE avec TVA et accès réglementé.",
  conseil: "Prime D2 = 30%-50%-80% coûts éligibles HTVA selon catégorie revenus. Traitement zones contaminées et enlèvement parties dégradées : décapage enduits/plafonnages contaminés, traitement bois, enlèvement boiseries atteintes, injection/pulvérisation sels fongicides/insecticides maçonneries, forage murs et pose cartouches fongicides. OBLIGATOIRE : rapport laboratoire agréé. Propriétaire occupant : engagement 5 ans résidence/non-vente si prime >30.000€.",
  document: "Attestation entrepreneur + attestation technique Champignons/moisissures/insectes + RAPPORT LABORATOIRE AGRÉÉ OBLIGATOIRE + factures détaillées libellées au nom du demandeur + preuves de paiement + documents catégorie revenus si autre que Cat.I + documents complémentaires (titre propriété, extrait cadastral, etc.).",
  specifique: "Bruxelles - Renolution D2 - Traitement scientifique contaminations biologiques",
  placeholder: JSON.parse('{
    "bruxelles_cat1": "Montant coûts éligibles HTVA (€) - 30%",
    "bruxelles_cat2": "Montant coûts éligibles HTVA (€) - 50%",
    "bruxelles_cat3": "Montant coûts éligibles HTVA (€) - 80%"
  }'),
  statut_compatible: ["residentiel"],
  image: "images/traitement_fongique.webp",
  region: "bruxelles",
  category_id: Category.find_by(code: "bruxelles_cat1", region: "bruxelles")&.id
)

puts "✅ Primes D (Salubrité) créées avec succès"
