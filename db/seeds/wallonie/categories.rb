puts "🏴󠁢󠁥󠁷󠁡󠁬󠁿 Création des catégories Wallonie..."

# Catégories de revenus officielles pour la Wallonie (2025)
# Basées sur le système R1 à R5 des primes wallonnes

Category.find_or_create_by!(
  code: "wallonie_r1",
  description: "Revenus très faibles",
  seuil_seul: 26900,
  couple_sans_charge: 26900,
  increment_par_personne: 5000,
)

Category.find_or_create_by!(
  code: "wallonie_r2",
  description: "Revenus faibles",
  seuil_seul: 38300,
  couple_sans_charge: 38300,
  increment_par_personne: 5000,
)

Category.find_or_create_by!(
  code: "wallonie_r3",
  description: "Revenus moyens",
  seuil_seul: 50600,
  couple_sans_charge: 50600,
  increment_par_personne: 5000,
)

Category.find_or_create_by!(
  code: "wallonie_r4",
  description: "Revenus élevés",
  seuil_seul: 114400,
  couple_sans_charge: 114400,
  increment_par_personne: 5000,
)

Category.find_or_create_by!(
  code: "wallonie_r5",
  description: "Revenus très élevés",
  seuil_seul: 999999,    # Pas de limite supérieure (Infinity)
  couple_sans_charge: 999999,
  increment_par_personne: 5000,
)

puts "✅ Catégories Wallonie créées avec succès"
