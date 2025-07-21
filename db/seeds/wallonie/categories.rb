puts "🏴󠁢󠁥󠁷󠁡󠁬󠁿 Création des catégories Wallonie..."

# Catégories de revenus officielles pour la Wallonie (2025)
# Basées sur le système R1 à R5 des primes wallonnes

Category.find_or_create_by(code: "wallonie_r1") do |cat|
  cat.region = "wallonie"
  cat.description = "Revenus très faibles"
  cat.seuil_seul = 26900
  cat.couple_sans_charge = 26900
  cat.increment_par_personne = 5000
end

Category.find_or_create_by(code: "wallonie_r2") do |cat|
  cat.region = "wallonie"
  cat.description = "Revenus faibles"
  cat.seuil_seul = 38300
  cat.couple_sans_charge = 38300
  cat.increment_par_personne = 5000
end

Category.find_or_create_by(code: "wallonie_r3") do |cat|
  cat.region = "wallonie"
  cat.description = "Revenus moyens"
  cat.seuil_seul = 50600
  cat.couple_sans_charge = 50600
  cat.increment_par_personne = 5000
end

Category.find_or_create_by(code: "wallonie_r4") do |cat|
  cat.region = "wallonie"
  cat.description = "Revenus élevés"
  cat.seuil_seul = 114400
  cat.couple_sans_charge = 114400
  cat.increment_par_personne = 5000
end

Category.find_or_create_by(code: "wallonie_r5") do |cat|
  cat.region = "wallonie"
  cat.description = "Revenus très élevés"
  cat.seuil_seul = 999999    # Pas de limite supérieure
  cat.couple_sans_charge = 999999
  cat.increment_par_personne = 5000
end

puts "✅ Catégories Wallonie créées avec succès"
