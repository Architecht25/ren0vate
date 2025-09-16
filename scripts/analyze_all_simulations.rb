#!/usr/bin/env ruby

puts "🔍 ANALYSE DE TOUTES LES SIMULATIONS"
puts "Vérifions l'état des 11 simulations après nos corrections..."

# Lister toutes les simulations existantes
simulations = Simulation.all.order(:id)

puts "\n📊 ÉTAT GÉNÉRAL:"
puts "Simulations trouvées: #{simulations.length}"

simulations.each do |sim|
  puts "\n📋 SIMULATION #{sim.id}:"
  puts "  💾 Total en base: #{sim.total_simule}€"
  puts "  🏷️ Catégorie: #{sim.category || sim.categorie || 'non définie'}"

  if sim.parameters.present?
    begin
      params = JSON.parse(sim.parameters)

      if params["prime_cards"]
        prime_count = 0
        total_calculated = 0

        params["prime_cards"].each do |category_key, category_data|
          if category_data["primes"]
            category_data["primes"].each do |prime|
              if prime["calculated_amount"].to_f > 0
                prime_count += 1
                total_calculated += prime["calculated_amount"].to_f
              end
            end
          end
        end

        puts "  🎯 Primes avec montant: #{prime_count}"
        puts "  📊 Total calculé params: #{total_calculated}€"
        puts "  🎯 Total general params: #{params['total_general']}€"

        # Détecter les incohérences
        if total_calculated != params['total_general'].to_f
          puts "  ❌ INCOHÉRENCE: calc ≠ general"
        end

        if params['total_general'].to_f != sim.total_simule
          puts "  ❌ INCOHÉRENCE: general ≠ base"
        end

        if total_calculated == params['total_general'].to_f && params['total_general'].to_f == sim.total_simule
          puts "  ✅ COHÉRENT"
        end

        # Montrer quelques primes importantes
        puts "  📝 Primes principales:"
        params["prime_cards"].each do |category_key, category_data|
          if category_data["primes"]
            category_data["primes"].each do |prime|
              amount = prime["calculated_amount"].to_f
              if amount > 100
                puts "    • #{prime['slug']}: #{amount}€"
              end
            end
          end
        end
      else
        puts "  ⚪ Pas de prime_cards"
      end
    rescue JSON::ParserError
      puts "  ❌ Erreur parse JSON"
    end
  else
    puts "  ⚪ Pas de paramètres"
  end

  puts "  " + "-" * 50
end

puts "\n🎯 RÉSUMÉ:"
coherent_count = 0
problematic_count = 0

simulations.each do |sim|
  if sim.parameters.present?
    begin
      params = JSON.parse(sim.parameters)
      if params["total_general"].to_f == sim.total_simule
        coherent_count += 1
      else
        problematic_count += 1
        puts "❌ Simulation #{sim.id}: incohérente"
      end
    rescue
      problematic_count += 1
    end
  else
    puts "⚪ Simulation #{sim.id}: pas de données"
  end
end

puts "\n📊 BILAN:"
puts "✅ Simulations cohérentes: #{coherent_count}"
puts "❌ Simulations problématiques: #{problematic_count}"
puts "📝 Total simulations: #{simulations.length}"

puts "\n✅ Analyse terminée!"
