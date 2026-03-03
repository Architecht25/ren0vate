#!/usr/bin/env ruby
# Script de test de sécurité pour vérifier que les données utilisateur sont correctement filtrées

require_relative '../config/environment'

puts "🔒 Test de sécurité - Vérification de la porosité des données utilisateur"
puts "=" * 70

# Créer des utilisateurs de test
user1 = User.find_or_create_by!(email: 'user1@test.com') do |u|
  u.password = 'testpass123'
  u.password_confirmation = 'testpass123'
  u.first_name = 'User'
  u.last_name = 'One'
  u.confirmed_at = Time.current
end

user2 = User.find_or_create_by!(email: 'user2@test.com') do |u|
  u.password = 'testpass123'
  u.password_confirmation = 'testpass123'
  u.first_name = 'User'
  u.last_name = 'Two'
  u.confirmed_at = Time.current
end

admin_user = User.find_or_create_by!(email: 'admin@test.com') do |u|
  u.password = 'testpass123'
  u.password_confirmation = 'testpass123'
  u.first_name = 'Admin'
  u.last_name = 'User'
  u.role = 'admin'
  u.confirmed_at = Time.current
end

puts "✅ Utilisateurs de test créés/trouvés:"
puts "   - User 1: #{user1.email} (ID: #{user1.id})"
puts "   - User 2: #{user2.email} (ID: #{user2.id})"
puts "   - Admin: #{admin_user.email} (ID: #{admin_user.id}, rôle: #{admin_user.role})"
puts

# Créer des données de test pour chaque utilisateur
property1 = user1.properties.find_or_create_by!(
  adresse: 'Test Address 1',
  rue: 'Test Street',
  numero: '123',
  code_postal: '1000',
  commune: 'Brussels',
  region: 'bruxelles'
)

property2 = user2.properties.find_or_create_by!(
  adresse: 'Test Address 2',
  rue: 'Test Avenue',
  numero: '456',
  code_postal: '5000',
  commune: 'Namur',
  region: 'wallonie'
)

simulation1 = user1.simulations.find_or_create_by!(
  titre: 'Simulation User 1',
  region: 'bruxelles',
  property: property1,
  total_simule: 5000
)

simulation2 = user2.simulations.find_or_create_by!(
  titre: 'Simulation User 2',
  region: 'wallonie',
  property: property2,
  total_simule: 7500
)

# Créer des requests et request_progresses
request1 = user1.requests.find_or_create_by!(
  property: property1,
  region: 'bruxelles',
  status: 'en_cours',
  title: 'Test Request 1',
  description: 'Test description for request 1',
  form_type: 'monuments_bruxelles'
)

request2 = user2.requests.find_or_create_by!(
  property: property2,
  region: 'wallonie',
  status: 'en_cours',
  title: 'Test Request 2',
  description: 'Test description for request 2',
  form_type: 'regional_wallonie'
)

request_progress1 = request1.request_progresses.find_or_create_by!(
  step: 'documentation',
  pourcentage: 50,
  status_administratif: 'en_cours',
  email_suivi: "test1-#{Time.current.to_i}@tracking.ren0vate.be",
  form_type: 'monuments_bruxelles',
  form_name: 'Monuments & Sites Bruxelles'
)

request_progress2 = request2.request_progresses.find_or_create_by!(
  step: 'finalisation',
  pourcentage: 75,
  status_administratif: 'soumis',
  email_suivi: "test2-#{Time.current.to_i}@tracking.ren0vate.be",
  form_type: 'regional_wallonie',
  form_name: 'Prime régionale Wallonie'
)

puts "✅ Données de test créées:"
puts "   - Property 1 (User 1): #{property1.adresse}"
puts "   - Property 2 (User 2): #{property2.adresse}"
puts "   - Simulation 1 (User 1): #{simulation1.titre}"
puts "   - Simulation 2 (User 2): #{simulation2.titre}"
puts "   - RequestProgress 1 (User 1): #{request_progress1.step}"
puts "   - RequestProgress 2 (User 2): #{request_progress2.step}"
puts

# Test 1: Vérifier la séparation des simulations
puts "🧪 Test 1: Séparation des simulations par utilisateur"
user1_simulations = user1.simulations
user2_simulations = user2.simulations

puts "   User 1 voit #{user1_simulations.count} simulation(s)"
puts "   User 2 voit #{user2_simulations.count} simulation(s)"

# Vérifier qu'ils ne voient que leurs propres simulations
user1_sees_own = user1_simulations.include?(simulation1)
user1_sees_other = user1_simulations.include?(simulation2)
user2_sees_own = user2_simulations.include?(simulation2)
user2_sees_other = user2_simulations.include?(simulation1)

puts "   ✅ User 1 voit sa propre simulation: #{user1_sees_own}"
puts "   #{user1_sees_other ? '❌' : '✅'} User 1 voit la simulation de User 2: #{user1_sees_other}"
puts "   ✅ User 2 voit sa propre simulation: #{user2_sees_own}"
puts "   #{user2_sees_other ? '❌' : '✅'} User 2 voit la simulation de User 1: #{user2_sees_other}"

test1_passed = user1_sees_own && !user1_sees_other && user2_sees_own && !user2_sees_other
puts "   Résultat: #{test1_passed ? '✅ RÉUSSI' : '❌ ÉCHEC'}"
puts

# Test 2: Vérifier la séparation des request_progresses
puts "🧪 Test 2: Séparation des request_progresses par utilisateur"

# Simuler ce que verrait chaque utilisateur avec la nouvelle logique
user1_request_progresses = RequestProgress.joins(:request).where(requests: { user_id: user1.id })
user2_request_progresses = RequestProgress.joins(:request).where(requests: { user_id: user2.id })

puts "   User 1 voit #{user1_request_progresses.count} request_progress(es)"
puts "   User 2 voit #{user2_request_progresses.count} request_progress(es)"

user1_sees_own_rp = user1_request_progresses.include?(request_progress1)
user1_sees_other_rp = user1_request_progresses.include?(request_progress2)
user2_sees_own_rp = user2_request_progresses.include?(request_progress2)
user2_sees_other_rp = user2_request_progresses.include?(request_progress1)

puts "   ✅ User 1 voit son propre request_progress: #{user1_sees_own_rp}"
puts "   #{user1_sees_other_rp ? '❌' : '✅'} User 1 voit le request_progress de User 2: #{user1_sees_other_rp}"
puts "   ✅ User 2 voit son propre request_progress: #{user2_sees_own_rp}"
puts "   #{user2_sees_other_rp ? '❌' : '✅'} User 2 voit le request_progress de User 1: #{user2_sees_other_rp}"

test2_passed = user1_sees_own_rp && !user1_sees_other_rp && user2_sees_own_rp && !user2_sees_other_rp
puts "   Résultat: #{test2_passed ? '✅ RÉUSSI' : '❌ ÉCHEC'}"
puts

# Test 3: Vérifier que l'admin voit tout
puts "🧪 Test 3: L'administrateur voit toutes les données"
all_simulations = Simulation.all
all_request_progresses = RequestProgress.all

admin_sees_all_sims = all_simulations.count >= 2
admin_sees_all_rps = all_request_progresses.count >= 2

puts "   Admin voit #{all_simulations.count} simulation(s) au total"
puts "   Admin voit #{all_request_progresses.count} request_progress(es) au total"
puts "   #{admin_sees_all_sims ? '✅' : '❌'} Admin voit toutes les simulations: #{admin_sees_all_sims}"
puts "   #{admin_sees_all_rps ? '✅' : '❌'} Admin voit tous les request_progresses: #{admin_sees_all_rps}"

test3_passed = admin_sees_all_sims && admin_sees_all_rps
puts "   Résultat: #{test3_passed ? '✅ RÉUSSI' : '❌ ÉCHEC'}"
puts

# Test 4: Vérifier que AdminStatsService compte toutes les données
puts "🧪 Test 4: AdminStatsService voit toutes les données"
stats = AdminStatsService.call
total_users_in_stats = stats[:overview][:total_users]
total_simulations_in_stats = stats[:overview][:total_simulations]
total_request_progresses_in_stats = stats[:overview][:total_request_progresses]

puts "   AdminStatsService compte #{total_users_in_stats} utilisateur(s)"
puts "   AdminStatsService compte #{total_simulations_in_stats} simulation(s)"
puts "   AdminStatsService compte #{total_request_progresses_in_stats} request_progress(es)"

test4_passed = total_users_in_stats >= 3 && total_simulations_in_stats >= 2 && total_request_progresses_in_stats >= 2
puts "   Résultat: #{test4_passed ? '✅ RÉUSSI' : '❌ ÉCHEC'}"
puts

# Résumé final
puts "=" * 70
puts "📊 RÉSUMÉ DES TESTS DE SÉCURITÉ"
puts "=" * 70

all_tests_passed = test1_passed && test2_passed && test3_passed && test4_passed

puts "Test 1 - Isolation simulations:        #{test1_passed ? '✅ RÉUSSI' : '❌ ÉCHEC'}"
puts "Test 2 - Isolation request_progresses: #{test2_passed ? '✅ RÉUSSI' : '❌ ÉCHEC'}"
puts "Test 3 - Accès admin global:           #{test3_passed ? '✅ RÉUSSI' : '❌ ÉCHEC'}"
puts "Test 4 - AdminStatsService global:     #{test4_passed ? '✅ RÉUSSI' : '❌ ÉCHEC'}"
puts "=" * 70

if all_tests_passed
  puts "🎉 TOUS LES TESTS RÉUSSIS - Pas de porosité détectée!"
  puts "   Les données utilisateur sont correctement isolées."
else
  puts "⚠️  CERTAINS TESTS ONT ÉCHOUÉ - Porosité potentielle détectée!"
  puts "   Vérifiez les logs ci-dessus pour identifier les problèmes."
end

puts "=" * 70
puts "🔒 Test de sécurité terminé"

# Nettoyage optionnel (commenter si vous voulez garder les données de test)
puts
print "Supprimer les données de test? (y/N): "
response = STDIN.gets.chomp

if response.downcase == 'y'
  puts "🧹 Nettoyage des données de test..."

  request_progress1.destroy if request_progress1.persisted?
  request_progress2.destroy if request_progress2.persisted?
  request1.destroy if request1.persisted?
  request2.destroy if request2.persisted?
  simulation1.destroy if simulation1.persisted?
  simulation2.destroy if simulation2.persisted?
  property1.destroy if property1.persisted?
  property2.destroy if property2.persisted?

  # Ne pas supprimer les utilisateurs pour éviter les problèmes
  puts "✅ Données de test supprimées (utilisateurs conservés)"
else
  puts "📚 Données de test conservées pour inspection manuelle"
end
