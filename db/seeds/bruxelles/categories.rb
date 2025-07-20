# Catégories de revenus officielles pour Bruxelles (2024)
# Basées sur le système Renolution - Catégories 1 à 4

puts "🏢 Création des catégories Bruxelles..."

Category.find_or_create_by!(
  code: "bruxelles_cat1",
  description: "Revenus modestes",
  seuil_seul: 37600,
  couple_sans_charge: 37600,
  increment_par_personne: 5000,
)

Category.find_or_create_by!(
  code: "bruxelles_cat2",
  description: "Revenus moyens",
  seuil_seul: 75100,
  couple_sans_charge: 75100,
  increment_par_personne: 5000,
)

Category.find_or_create_by!(
  code: "bruxelles_cat3",
  description: "Revenus intermédiaires",
  seuil_seul: 93000,
  couple_sans_charge: 93000,
  increment_par_personne: 5000,
)

Category.find_or_create_by!(
  code: "bruxelles_cat4",
  description: "Revenus élevés (hors barème)",
  seuil_seul: 999999,    # Au-dessus de 93 000€ (non éligible)
  couple_sans_charge: 999999,
  increment_par_personne: 5000,
)

puts "✅ Catégories Bruxelles créées avec succès"
