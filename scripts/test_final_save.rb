#!/usr/bin/env ruby

puts "🔧 Test final de sauvegarde simulation 70..."

sim = Simulation.find(70)
puts "📊 État initial: #{sim.total_simule}€"

# Test avec une vraie sauvegarde pour 20m²
updater = SimulationPrimesUpdater.new(sim)
result = updater.update_user_inputs({'ramen_deuren' => '20'})

if result[:success]
  sim.reload
  puts "✅ Sauvegarde réussie!"
  puts "💰 Nouveau total: #{sim.total_simule}€"
  puts "📊 Total calculé: #{result[:total_amount]}€"
  puts "🎯 Attendu: 1280€ (20m² × 64€/m²)"

  # Vérifier si le calcul est correct
  if sim.total_simule == 1280.0
    puts "🎉 PARFAIT! Le calcul et la sauvegarde sont corrects!"
  else
    puts "⚠️ Montant inattendu"
  end
else
  puts "❌ Échec: #{result[:error]}"
end
