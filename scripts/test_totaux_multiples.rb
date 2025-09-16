#!/usr/bin/env ruby

puts "🔧 Test totaux multiples simulation 70"

sim = Simulation.find(70)
puts "📊 Simulation: #{sim.id}"

# Test avec plusieurs cartes pour reproduire le cas 5037€
user_inputs = {
  'ramen_deuren' => '20',            # 20m² × 64€ = 1280€
  'isolation_toiture' => '100',      # 100m² × 16€ = 1600€ (max 100m²)
  'isolation_murs_cat12' => '100',   # 100m² × 22.5€ = 2250€ (max 100m²)
  'isolation_sol' => '50'            # 50m² × 15€ = 750€
}

puts "📝 Inputs: #{user_inputs.inspect}"
puts "🎯 Calcul attendu:"
puts "  • ramen_deuren: 20 × 64 = 1280€"
puts "  • isolation_toiture: 100 × 16 = 1600€"
puts "  • isolation_murs_cat12: 100 × 22.5 = 2250€"
puts "  • isolation_sol: 50 × 15 = 750€"
puts "  📊 Total attendu: 5880€"

begin
  updater = SimulationPrimesUpdater.new(sim)
  result = updater.update_user_inputs(user_inputs)

  if result[:success]
    puts "\n✅ Sauvegarde réussie!"
    puts "💰 Total calculé: #{result[:total_amount]}€"

    sim.reload
    puts "💾 Total en base: #{sim.total_simule}€"

    # Analyser les détails
    if sim.parameters.present?
      params = JSON.parse(sim.parameters)
      puts "\n📋 Détail des catégories:"
      if params["prime_cards"]
        total_verification = 0
        params["prime_cards"].each do |category_key, category_data|
          puts "  #{category_key}: #{category_data['total']}€"
          total_verification += category_data['total'].to_f
          if category_data["primes"]
            category_data["primes"].each do |prime|
              input_val = prime["user_input_value"] || "0"
              calc_amount = prime["calculated_amount"] || 0
              puts "    • #{prime['slug']}: #{input_val} → #{calc_amount}€"
            end
          end
        end
        puts "📊 Total vérification: #{total_verification}€"
      end
    end

    # Vérifier la cohérence
    if sim.total_simule == result[:total_amount]
      puts "🎉 PARFAIT! Cohérence entre calcul et sauvegarde!"
    else
      puts "⚠️ INCOHÉRENCE détectée!"
    end

  else
    puts "❌ Échec: #{result[:error]}"
  end

rescue => e
  puts "💥 Exception: #{e.message}"
  puts "📍 Première ligne: #{e.backtrace[0]}"
end

puts "\n✅ Test terminé!"
