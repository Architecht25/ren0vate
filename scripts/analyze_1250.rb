#!/usr/bin/env ruby

sim = Simulation.find(70)
puts "🔍 Analyse complète simulation 70"
puts "Total en base: #{sim.total_simule}€"

if sim.parameters.present?
  params = JSON.parse(sim.parameters)
  puts "\n📋 Détail de tous les montants:"

  total_verification = 0
  if params['prime_cards']
    params['prime_cards'].each do |category_key, category_data|
      puts "\n📁 Catégorie #{category_key}: #{category_data['total']}€"
      total_verification += category_data['total'].to_f

      if category_data['primes']
        category_data['primes'].each do |prime|
          input_val = prime['user_input_value'] || '0'
          calc_amount = prime['calculated_amount'] || 0
          if calc_amount.to_f > 0
            puts "  ✅ #{prime['slug']}: #{input_val} → #{calc_amount}€"
          else
            puts "  ⚪ #{prime['slug']}: #{input_val} → #{calc_amount}€"
          end
        end
      end
    end
  end

  puts "\n📊 Total par addition: #{total_verification}€"
  puts "📊 Total params['total_general']: #{params['total_general']}€"
  puts "📊 Total en base: #{sim.total_simule}€"

  if total_verification != sim.total_simule
    puts "⚠️ INCOHÉRENCE DÉTECTÉE!"
  else
    puts "✅ Cohérence OK"
  end

  # Chercher spécifiquement d'où viennent les 1250€
  puts "\n🔍 Recherche source des 1250€:"
  params['prime_cards'].each do |category_key, category_data|
    if category_data['primes']
      category_data['primes'].each do |prime|
        amount = prime['calculated_amount'].to_f
        if amount == 1250.0
          puts "🎯 TROUVÉ! #{prime['slug']}: #{amount}€"
          puts "   Input: #{prime['user_input_value']}"
          puts "   Données: #{prime['category_data']}"
        end
      end
    end
  end
else
  puts "❌ Pas de paramètres trouvés"
end
