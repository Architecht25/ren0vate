#!/usr/bin/env ruby

puts "🔧 Test des différentes cartes Flandre..."

sim = Simulation.find(70)
puts "📊 Simulation: #{sim.id}"

# Lister les différentes cartes à tester
cartes_test = [
  'ramen_deuren',      # Fonctionne
  'isolation_toiture', # À tester
  'warmtepomp',        # À tester
  'warmtepompboiler',  # À tester
  'isolation_murs_cat12', # À tester
  'voorbereiding_isolatie' # À tester
]

cartes_test.each do |carte|
  puts "\n🎯 Test carte: #{carte}"

  begin
    updater = SimulationPrimesUpdater.new(sim)

    # Tester avec une valeur simple
    test_value = case carte
                 when 'isolation_toiture', 'isolation_murs_cat12'
                   '10' # 10m²
                 when 'warmtepomp', 'warmtepompboiler'
                   '1' # 1 unité
                 else
                   '5' # valeur générique
                 end

    user_inputs = {carte => test_value}
    puts "📝 Test avec: #{user_inputs.inspect}"

    result = updater.update_user_inputs(user_inputs)

    if result[:success]
      puts "✅ #{carte}: Succès - #{result[:total_amount]}€"
    else
      puts "❌ #{carte}: Échec - #{result[:error]}"
    end

  rescue => e
    puts "💥 #{carte}: Exception - #{e.message}"
    puts "📍 Première ligne erreur: #{e.backtrace[0]}"
  end
end

puts "\n✅ Test terminé!"
