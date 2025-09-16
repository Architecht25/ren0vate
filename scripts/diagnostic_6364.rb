#!/usr/bin/env ruby

puts "🚨 NOUVEAU PROBLÈME: 4164€ attendu vs 6364€ sauvegardé"
puts "🔍 Surplus mystérieux: #{6364 - 4164} = 2200€"

sim = Simulation.find(70)
puts "📊 Simulation: #{sim.id}"
puts "💾 Total en base: #{sim.total_simule}€"

if sim.parameters.present?
  params = JSON.parse(sim.parameters)
  puts "\n📋 ANALYSE COMPLÈTE DE LA SAUVEGARDE:"
  puts "🎯 total_general: #{params['total_general']}€"
  puts "🎯 total: #{params['total']}€"
  puts "🎯 timestamp: #{params['calculation_timestamp']}"

  if params["prime_cards"]
    total_verification = 0
    puts "\n📁 TOUTES LES PRIMES SAUVEGARDÉES:"

    params["prime_cards"].each do |category_key, category_data|
      puts "\n  📂 #{category_key.upcase}: #{category_data['total']}€"
      total_verification += category_data['total'].to_f

      if category_data["primes"]
        category_data["primes"].each do |prime|
          input_val = prime['user_input_value'] || '0'
          calc_amount = prime['calculated_amount'] || 0
          status = case calc_amount.to_f
                   when 0
                     "⚪"
                   when 1..999
                     "🟡"
                   else
                     "🔴"
                   end
          puts "    #{status} #{prime['slug']}: #{input_val} → #{calc_amount}€"
        end
      end
    end

    puts "\n🔍 VÉRIFICATIONS:"
    puts "  Addition manuelle: #{total_verification}€"
    puts "  Total general params: #{params['total_general']}€"
    puts "  Total en base: #{sim.total_simule}€"

    # Rechercher les primes qui totalisent ~2200€
    puts "\n🎯 RECHERCHE DU SURPLUS 2200€:"
    puts "Primes qui pourraient expliquer ce montant:"

    params["prime_cards"].each do |category_key, category_data|
      if category_data["primes"]
        category_data["primes"].each do |prime|
          amount = prime['calculated_amount'].to_f
          if amount > 1000 # Primes importantes
            puts "  🔴 #{prime['slug']}: #{amount}€"
          end
        end
      end
    end

    # Calculer ce qui DEVRAIT être là
    puts "\n✅ CE QUI DEVRAIT ÊTRE SAUVÉ:"
    puts "  • isolation_toiture (100m²): 1600€"
    puts "  • isolation_murs_cat12 (200m² → max 100m²): 2250€"
    puts "  • warmtepompboiler (1256€ → plafond 25%): 314€"
    puts "  📊 TOTAL ATTENDU: 4164€"

    excess = total_verification - 4164
    if excess > 0
      puts "\n⚠️ SURPLUS DÉTECTÉ: +#{excess}€"
      puts "Des primes supplémentaires ont été ajoutées!"
    end
  end
else
  puts "❌ Aucun paramètre trouvé"
end

puts "\n✅ Diagnostic terminé!"
