# Seed data pour tester le pricing
# rails db:seed:pricing

puts "🌱 Seeding pricing test data..."

# Créer un utilisateur de test s'il n'existe pas
test_user = User.find_or_create_by(email: "test@ren0vate.be") do |user|
  user.first_name = "Test"
  user.last_name = "User"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.confirmed_at = Time.current
end

puts "👤 Utilisateur de test créé: #{test_user.email}"

# Créer quelques propriétés pour tester les recommandations
3.times do |i|
  property = test_user.properties.find_or_create_by(
    rue: "Rue de Test #{i+1}",
    numero: "#{i+1}",
    code_postal: "1000",
    commune: "Bruxelles",
    region: "Bruxelles"
  ) do |prop|
    prop.type_bien_bruxelles = "maison"
    prop.annee_construction = 1980 + i*10
  end

  puts "🏠 Propriété créée: #{property.full_address}"
end

# Créer quelques simulations
2.times do |i|
  simulation = test_user.simulations.find_or_create_by(
    titre: "Simulation Test #{i+1}",
    region: "Bruxelles",
    property: test_user.properties.first
  ) do |sim|
    sim.eligible = true
    sim.total_amount = 5000 + (i * 2000)
  end

  puts "🧮 Simulation créée: #{simulation.titre}"
end

# Créer un projet de test
project = test_user.projects.find_or_create_by(
  title: "Projet de rénovation test",
  property: test_user.properties.first
) do |proj|
  proj.description = "Isolation et chauffage"
  proj.budget = 25000
  proj.status = "en_cours"
end

puts "🚧 Projet créé: #{project.title}"

puts "✅ Seeding pricing terminé!"
puts ""
puts "🔗 URLs de test:"
puts "- Pricing public: http://localhost:3000/pricing"
puts "- Pricing sélection: http://localhost:3000/pricing/select"
puts "- Login test: #{test_user.email} / password123"
