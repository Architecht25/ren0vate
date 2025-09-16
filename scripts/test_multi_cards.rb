#!/usr/bin/env ruby

puts "🎉 Test final: vérification complète simulation 70"

sim = Simulation.find(70)
puts "📊 Simulation: #{sim.id} - Catégorie: #{sim.category}"

# Test avec plusieurs cartes en même temps
puts "\n🔧 Test multi-cartes..."
user_inputs = {
  'ramen_deuren' => '20',           # 20m² × 64€ = 1280€
  'isolation_toiture' => '15',      # 15m² × 16€ = 240€
  'warmtepomp' => '1'               # 1 unité = 2012.5€
}

puts "📝 Inputs: #{user_inputs.inspect}"

begin
  updater = SimulationPrimesUpdater.new(sim)
  result = updater.update_user_inputs(user_inputs)

  if result[:success]
    sim.reload
    puts "✅ Sauvegarde multi-cartes réussie!"
    puts "💰 Total en base: #{sim.total_simule}€"
    puts "📊 Total calculé: #{result[:total_amount]}€"
    puts "🎯 Estimation: ~3532.5€ (1280 + 240 + 2012.5)"

    # Vérifier les données sauvegardées
    if sim.parameters.present?
      params = JSON.parse(sim.parameters)
      puts "\n📋 Structure sauvegardée:"
      if params["prime_cards"]
        params["prime_cards"].each do |category, data|
          puts "  #{category}: #{data['total']}€ (#{data['primes']&.size || 0} primes)"
        end
      end
    end

  else
    puts "❌ Échec: #{result[:error]}"
  end

rescue => e
  puts "💥 Exception: #{e.message}"
end

puts "\n🎉 Test terminé!"
