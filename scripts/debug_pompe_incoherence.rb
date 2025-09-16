#!/usr/bin/env ruby

puts "🔍 Diagnostic incohérence pompe à chaleur 4000€ vs 1250€"

sim = Simulation.find(70)
puts "📊 Simulation: #{sim.id}"

# Récupérer l'état actuel de la simulation
if sim.parameters.present?
  current_params = JSON.parse(sim.parameters)
  puts "\n📋 État actuel des paramètres:"
  if current_params["prime_cards"]
    current_params["prime_cards"].each do |category_key, category_data|
      puts "📁 Catégorie #{category_key}: #{category_data['total']}€"
      if category_data["primes"]
        category_data["primes"].each do |prime|
          if prime["slug"] == "warmtepomp"
            puts "  🎯 POMPE À CHALEUR:"
            puts "    Input utilisateur: #{prime['user_input_value']}"
            puts "    Montant calculé: #{prime['calculated_amount']}€"
            puts "    Données catégorie: #{prime['category_data']&.inspect}"
          end
        end
      end
    end
  end
end

# Test avec différentes valeurs pour comprendre
test_values = ['1', '4000', '5000', '10000']

test_values.each do |val|
  puts "\n🔧 Test avec valeur: #{val}"

  begin
    updater = SimulationPrimesUpdater.new(sim)
    result = updater.update_user_inputs({'warmtepomp' => val})

    if result[:success]
      puts "  ✅ Calculé: #{result[:total_amount]}€"

      # Analyser les détails
      if result[:updated_cards] && result[:updated_cards]["general"]
        general_primes = result[:updated_cards]["general"][:primes]
        warmtepomp_prime = general_primes.find { |p| p[:slug] == "warmtepomp" }
        if warmtepomp_prime
          puts "  📊 Détail: input=#{warmtepomp_prime[:user_input_value]} → montant=#{warmtepomp_prime[:calculated_amount]}€"
        end
      end
    else
      puts "  ❌ Erreur: #{result[:error]}"
    end
  rescue => e
    puts "  💥 Exception: #{e.message}"
  end
end

puts "\n✅ Diagnostic terminé!"
