# Catégories de revenus officielles pour Bruxelles (2024)
# Basées sur le système RENOLUTION - Catégories 1 à 3

puts "🏢 Création des catégories Bruxelles..."

Category.find_or_create_by(code: "bruxelles_cat1") do |cat|
  cat.region = "bruxelles"
  cat.description = "Revenus modestes - Primes RENOLUTION maximales"
  cat.seuil_seul = 37600
  cat.couple_sans_charge = 37600
  cat.increment_par_personne = 5000
  cat.autre_bien_interdit = false
  cat.location_sociale_autorisee = true
  cat.eligible_pour_verbouwlening = false  # Pas de verbouwlening à Bruxelles
end

Category.find_or_create_by(code: "bruxelles_cat2") do |cat|
  cat.region = "bruxelles"
  cat.description = "Revenus moyens - Primes RENOLUTION moyennes"
  cat.seuil_seul = 75100
  cat.couple_sans_charge = 75100
  cat.increment_par_personne = 5000
  cat.autre_bien_interdit = false
  cat.location_sociale_autorisee = false
  cat.eligible_pour_verbouwlening = false
end

Category.find_or_create_by(code: "bruxelles_cat3") do |cat|
  cat.region = "bruxelles"
  cat.description = "Revenus élevés - Primes RENOLUTION de base"
  cat.seuil_seul = 93000
  cat.couple_sans_charge = 93000
  cat.increment_par_personne = 5000
  cat.autre_bien_interdit = true
  cat.location_sociale_autorisee = false
  cat.eligible_pour_verbouwlening = false
end

puts "✅ Catégories Bruxelles créées avec succès"
