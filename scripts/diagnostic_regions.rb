#!/usr/bin/env ruby

puts "🔬 DIAGNOSTIC APPROFONDI DES PRIMES PAR RÉGION"
puts "Basé sur le calibrage réussi de la simulation 70 Flandre"
puts "=" * 60

# Simulations à analyser
simulations_to_analyze = {
  "Bruxelles" => [61, 68],
  "Wallonie" => [66]
}

def analyze_prime_calculation(prime, region)
  puts "    📊 #{prime['slug']}: #{prime['calculated_amount']}€"

  # Analyser les paramètres de calcul
  if prime['calculation_params']
    params = prime['calculation_params']
    puts "      🔧 Type calcul: #{params['calculation_type']}"
    puts "      📐 Surface: #{params['surface_m2']}m²" if params['surface_m2']
    puts "      💶 Montant/m²: #{params['montant_par_m2']}€" if params['montant_par_m2']
    puts "      🎯 Plafond: #{params['plafond']}€" if params['plafond']
    puts "      📋 Catégorie: #{params['categorie']}" if params['categorie']

    # Vérifier la cohérence du calcul
    if params['calculation_type'] == 'montant_m2_et_limite'
      expected = (params['surface_m2'].to_f * params['montant_par_m2'].to_f).round(2)
      if params['plafond'] && expected > params['plafond'].to_f
        expected = params['plafond'].to_f
      end

      if expected != prime['calculated_amount'].to_f
        puts "      ❌ ERREUR CALCUL: attendu #{expected}€, obtenu #{prime['calculated_amount']}€"
        return false
      else
        puts "      ✅ Calcul correct"
        return true
      end
    elsif params['calculation_type'] == 'forfait_et_plafond_facture'
      puts "      💡 Forfait avec plafond facture"
      return true
    elsif params['calculation_type'] == 'montant_variable_m2_et_limite'
      puts "      📊 Montant variable par m² avec limite"
      return true
    else
      puts "      ⚠️ Type de calcul non reconnu"
      return false
    end
  else
    puts "      ❌ Pas de paramètres de calcul"
    return false
  end
end

def analyze_simulation(sim_id, region)
  puts "\n🏢 ANALYSE SIMULATION #{sim_id} - #{region.upcase}"
  puts "-" * 50

  sim = Simulation.find(sim_id)
  puts "💾 Total en base: #{sim.total_simule}€"
  puts "🏷️ Catégorie: #{sim.category || sim.categorie}"

  if sim.parameters.blank?
    puts "❌ Pas de paramètres - simulation vide"
    return
  end

  begin
    params = JSON.parse(sim.parameters)

    if params["prime_cards"].blank?
      puts "❌ Pas de prime_cards"
      return
    end

    total_calculated = 0
    prime_count = 0
    calculation_errors = 0

    # Analyser chaque région dans les prime_cards
    params["prime_cards"].each do |region_key, region_data|
      next unless region_data["primes"]

      puts "\n  🗺️ Région: #{region_key}"

      region_data["primes"].each do |prime|
        amount = prime["calculated_amount"].to_f
        if amount > 0
          prime_count += 1
          total_calculated += amount

          is_correct = analyze_prime_calculation(prime, region)
          calculation_errors += 1 unless is_correct
        end
      end
    end

    puts "\n📊 RÉSUMÉ SIMULATION #{sim_id}:"
    puts "  🎯 Primes actives: #{prime_count}"
    puts "  💰 Total calculé: #{total_calculated}€"
    puts "  💾 Total en base: #{sim.total_simule}€"
    puts "  🎯 Total général params: #{params['total_general']}€"
    puts "  ❌ Erreurs de calcul: #{calculation_errors}"

    # Vérifier les cohérences
    if total_calculated != params['total_general'].to_f
      puts "  ❌ INCOHÉRENCE: calculé (#{total_calculated}€) ≠ général (#{params['total_general']}€)"
    end

    if params['total_general'].to_f != sim.total_simule
      puts "  ❌ INCOHÉRENCE: général (#{params['total_general']}€) ≠ base (#{sim.total_simule}€)"
    end

    if total_calculated == params['total_general'].to_f && params['total_general'].to_f == sim.total_simule
      puts "  ✅ PARFAITEMENT COHÉRENT"
    end

  rescue JSON::ParserError => e
    puts "❌ Erreur JSON: #{e.message}"
  rescue => e
    puts "❌ Erreur analyse: #{e.message}"
  end
end

# Lancer l'analyse pour chaque région
simulations_to_analyze.each do |region, sim_ids|
  puts "\n" + "=" * 60
  puts "🗺️ RÉGION #{region.upcase}"
  puts "=" * 60

  sim_ids.each do |sim_id|
    analyze_simulation(sim_id, region)
  end
end

puts "\n" + "=" * 60
puts "🎯 COMPARAISON AVEC FLANDRE (Simulation 70)"
puts "=" * 60

analyze_simulation(70, "Flandre")

puts "\n✅ Diagnostic terminé!"
puts "🔧 Prêt pour les corrections basées sur ces analyses"
