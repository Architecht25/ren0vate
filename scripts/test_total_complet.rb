#!/usr/bin/env ruby

puts "🔧 Test complet avec pompe à chaleur..."

sim = Simulation.find(70)
puts "📊 Simulation: #{sim.id}"

# Test avec isolation toiture + pompe à chaleur
user_inputs = {
  'isolation_toiture' => '100',  # 100m² → 1600€
  'warmtepomp' => '5000'         # 5000€ facture → 1250€
}

puts "📝 Inputs: #{user_inputs.inspect}"
puts "🎯 Attendu:"
puts "  • isolation_toiture: 100m² × 16€ = 1600€"
puts "  • warmtepomp: min(2250€, 25% × 5000€) = 1250€"
puts "  📊 Total attendu: 2850€"

begin
  updater = SimulationPrimesUpdater.new(sim)
  result = updater.update_user_inputs(user_inputs)

  if result[:success]
    puts "\n✅ Sauvegarde réussie!"
    puts "💰 Total calculé par service: #{result[:total_amount]}€"

    # Analyser la réponse détaillée
    puts "\n📊 Détail des cartes retournées:"
    if result[:updated_cards]
      total_verification = 0
      result[:updated_cards].each do |category, data|
        puts "  #{category}: #{data[:total]}€"
        total_verification += data[:total]
        data[:primes].each do |prime|
          puts "    • #{prime[:slug]}: #{prime[:user_input_value]} → #{prime[:calculated_amount]}€"
        end
      end
      puts "  📊 Total vérification réponse: #{total_verification}€"
    end

    # Vérifier ce qui est sauvé en base
    sim.reload
    puts "\n💾 Après sauvegarde:"
    puts "  Total en base: #{sim.total_simule}€"

    # Analyser les paramètres sauvés
    if sim.parameters.present?
      params = JSON.parse(sim.parameters)
      puts "\n📋 Paramètres sauvés:"
      puts "  total_general: #{params['total_general']}€"

      if params["prime_cards"]
        total_params = 0
        params["prime_cards"].each do |category_key, category_data|
          puts "  #{category_key}: #{category_data['total']}€"
          total_params += category_data['total'].to_f
          if category_data["primes"]
            category_data["primes"].each do |prime|
              if prime["calculated_amount"].to_f > 0
                puts "    ✅ #{prime['slug']}: #{prime['calculated_amount']}€"
              end
            end
          end
        end
        puts "  📊 Total par addition params: #{total_params}€"
      end
    end

    # Détecter les incohérences
    puts "\n🔍 Vérification cohérence:"
    puts "  Service calculé: #{result[:total_amount]}€"
    puts "  Base de données: #{sim.total_simule}€"
    puts "  Params total_general: #{params&.dig('total_general')}€"

    if result[:total_amount] == sim.total_simule
      puts "  ✅ Service ↔ Base: OK"
    else
      puts "  ❌ Service ↔ Base: INCOHÉRENT!"
    end

  else
    puts "❌ Échec: #{result[:error]}"
  end

rescue => e
  puts "💥 Exception: #{e.message}"
  puts "📍 Trace: #{e.backtrace[0..2].join("\n")}"
end

puts "\n✅ Test terminé!"
