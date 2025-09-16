#!/usr/bin/env ruby

puts "🔧 Test pompe à chaleur après correction..."

sim = Simulation.find(70)
puts "📊 Simulation: #{sim.id} - Catégorie: #{sim.category}"

# Test 1: Sans montant facture (juste forfait de base)
puts "\n🔧 Test 1: Forfait de base (sans facture)"
user_inputs = {'warmtepomp' => '1'}

updater = SimulationPrimesUpdater.new(sim)
result = updater.update_user_inputs(user_inputs)

if result[:success]
  puts "✅ Test 1 réussi!"
  puts "💰 Total calculé: #{result[:total_amount]}€"
  puts "🎯 Attendu: 2250€ (forfait air-eau catégorie 2)"
else
  puts "❌ Test 1 échec: #{result[:error]}"
end

# Test 2: Avec montant facture élevé (plafond pourcentage s'applique)
puts "\n🔧 Test 2: Avec facture élevée (plafond 25%)"
user_inputs = {'warmtepomp' => '20000'} # 20000€ de facture

updater = SimulationPrimesUpdater.new(sim)
result = updater.update_user_inputs(user_inputs)

if result[:success]
  puts "✅ Test 2 réussi!"
  puts "💰 Total calculé: #{result[:total_amount]}€"
  puts "🎯 Attendu: 2250€ (min entre forfait 2250€ et plafond 25% × 20000 = 5000€)"
else
  puts "❌ Test 2 échec: #{result[:error]}"
end

# Test 3: Avec facture modérée (plafond plus restrictif)
puts "\n🔧 Test 3: Avec facture modérée (plafond restrictif)"
user_inputs = {'warmtepomp' => '5000'} # 5000€ de facture

updater = SimulationPrimesUpdater.new(sim)
result = updater.update_user_inputs(user_inputs)

if result[:success]
  puts "✅ Test 3 réussi!"
  puts "💰 Total calculé: #{result[:total_amount]}€"
  puts "🎯 Attendu: 1250€ (min entre forfait 2250€ et plafond 25% × 5000 = 1250€)"

  sim.reload
  puts "💾 Total en base: #{sim.total_simule}€"
else
  puts "❌ Test 3 échec: #{result[:error]}"
end

puts "\n✅ Tests terminés!"
