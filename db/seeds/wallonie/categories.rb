puts "🏴󠁢󠁥󠁷󠁡󠁬󠁿 Création des catégories Wallonie..."

# Catégories de revenus officielles pour la Wallonie (2025)
# Basées sur le système R1 à R5 des primes wallonnes
# Seuils alignés avec wallonie_category_service.rb

Category.find_or_create_by(code: "wallonie_r1") do |cat|
  cat.region = "wallonie"
  cat.description = "Revenus très modestes (≤ 25.400€) - Primes maximales"
  cat.seuil_seul = 25400
  cat.couple_sans_charge = 25400
  cat.increment_par_personne = 5000
end

Category.find_or_create_by(code: "wallonie_r2") do |cat|
  cat.region = "wallonie"
  cat.description = "Revenus modestes (25.401€ - 36.200€) - Primes élevées"
  cat.seuil_seul = 36200
  cat.couple_sans_charge = 36200
  cat.increment_par_personne = 5000
end

Category.find_or_create_by(code: "wallonie_r3") do |cat|
  cat.region = "wallonie"
  cat.description = "Revenus moyens (36.201€ - 51.800€) - Primes moyennes"
  cat.seuil_seul = 51800
  cat.couple_sans_charge = 51800
  cat.increment_par_personne = 5000
end

Category.find_or_create_by(code: "wallonie_r4") do |cat|
  cat.region = "wallonie"
  cat.description = "Revenus moyens supérieurs (51.801€ - 79.000€) - Primes réduites"
  cat.seuil_seul = 79000
  cat.couple_sans_charge = 79000
  cat.increment_par_personne = 5000
end

Category.find_or_create_by(code: "wallonie_r5") do |cat|
  cat.region = "wallonie"
  cat.description = "Revenus supérieurs (79.001€ - 114.400€) - Primes minimales"
  cat.seuil_seul = 114400
  cat.couple_sans_charge = 114400
  cat.increment_par_personne = 5000
end

puts "✅ Catégories Wallonie créées avec succès (seuils harmonisés)"
