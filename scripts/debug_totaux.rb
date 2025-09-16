#!/usr/bin/env ruby

puts "🔍 Diagnostic incohérence totaux simulation 70"

sim = Simulation.find(70)
puts "📊 Simulation: #{sim.id}"
puts "💰 Total en base actuellement: #{sim.total_simule}€"

# Récupérer les paramètres actuels
if sim.parameters.present?
  current_params = JSON.parse(sim.parameters)
  puts "\n📋 État actuel des paramètres:"
  puts "🎯 Total général: #{current_params['total_general']}€"
  puts "🎯 Total: #{current_params['total']}€"

  if current_params["prime_cards"]
    current_params["prime_cards"].each do |category_key, category_data|
      puts "\n📁 Catégorie #{category_key}: #{category_data['total']}€"
      if category_data["primes"]
        category_data["primes"].each do |prime|
          input_val = prime["user_input_value"] || "0"
          calc_amount = prime["calculated_amount"] || 0
          puts "  • #{prime['slug']}: #{input_val} → #{calc_amount}€"
        end
      end
    end
  end
end

# Test avec des valeurs spécifiques problématiques
puts "\n🔧 Test isolation_murs_cat12..."
user_inputs = {'isolation_murs_cat12' => '100'} # 100m²

begin
  updater = SimulationPrimesUpdater.new(sim)
  result = updater.update_user_inputs(user_inputs)

  if result[:success]
    puts "✅ Test isolation_murs_cat12 réussi"
    puts "💰 Total calculé: #{result[:total_amount]}€"

    # Analyser la réponse détaillée
    if result[:updated_cards]
      puts "\n📊 Cartes mises à jour:"
      result[:updated_cards].each do |category, data|
        puts "  #{category}: #{data[:total]}€"
        data[:primes].each do |prime|
          puts "    • #{prime[:slug]}: #{prime[:user_input_value]} → #{prime[:calculated_amount]}€"
        end
      end
    end

    # Vérifier ce qui est vraiment sauvé
    sim.reload
    puts "\n💾 Après sauvegarde en base: #{sim.total_simule}€"

  else
    puts "❌ Échec: #{result[:error]}"
  end

rescue => e
  puts "💥 Exception: #{e.message}"
  puts "📍 Première ligne: #{e.backtrace[0]}"
end

puts "\n✅ Diagnostic terminé!"
