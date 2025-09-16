#!/usr/bin/env ruby

puts "🚨 DIAGNOSTIC URGENT - Écart de 1500€"

sim = Simulation.find(70)
puts "📊 Simulation: #{sim.id}"
puts "💾 Total sauvegardé: #{sim.total_simule}€"

# Afficher l'état actuel complet
if sim.parameters.present?
  params = JSON.parse(sim.parameters)
  puts "\n📋 ÉTAT COMPLET DE LA SAUVEGARDE:"
  puts "🎯 total_general: #{params['total_general']}€"
  puts "🎯 total: #{params['total']}€"
  puts "🎯 category_used: #{params['category_used']}"
  puts "🎯 timestamp: #{params['calculation_timestamp']}"

  if params["prime_cards"]
    total_verification = 0
    puts "\n📁 DÉTAIL PAR CATÉGORIE:"
    params["prime_cards"].each do |category_key, category_data|
      puts "\n  📂 #{category_key.upcase}: #{category_data['total']}€"
      total_verification += category_data['total'].to_f

      if category_data["primes"]
        category_data["primes"].each do |prime|
          input_val = prime['user_input_value'] || '0'
          calc_amount = prime['calculated_amount'] || 0
          status = calc_amount.to_f > 0 ? "✅" : "⚪"
          puts "    #{status} #{prime['slug']}: #{input_val} → #{calc_amount}€"
        end
      end
    end

    puts "\n🔍 VÉRIFICATIONS:"
    puts "  Addition manuelle: #{total_verification}€"
    puts "  Params total_general: #{params['total_general']}€"
    puts "  Base de données: #{sim.total_simule}€"

    # Détecter les incohérences
    if total_verification != params['total_general'].to_f
      puts "  ❌ INCOHÉRENCE: Addition ≠ total_general"
      puts "  🔴 Écart: #{(total_verification - params['total_general'].to_f).abs}€"
    end

    if params['total_general'].to_f != sim.total_simule
      puts "  ❌ INCOHÉRENCE: total_general ≠ base"
      puts "  🔴 Écart: #{(params['total_general'].to_f - sim.total_simule).abs}€"
    end

    if total_verification == params['total_general'].to_f && params['total_general'].to_f == sim.total_simule
      puts "  ✅ COHÉRENCE: Tous les totaux correspondent"
    end
  end
else
  puts "❌ Aucun paramètre trouvé"
end

# Rechercher spécifiquement où pourrait être l'écart de 1500€
puts "\n🔍 RECHERCHE DE L'ÉCART 1500€:"
puts "Si l'affichage montre 1500€ de plus, cherchons les primes de ce montant..."

# Lister toutes les primes flandre pour voir les montants possibles
Prime.where(region: 'flandre').each do |prime|
  if prime.valeurs_par_categorie.is_a?(Hash)
    cat_2_data = prime.valeurs_par_categorie['2']
    if cat_2_data
      case cat_2_data['type']
      when 'forfait_et_plafond_facture'
        if cat_2_data['forfaits']
          cat_2_data['forfaits'].each do |type, montant|
            if montant == 1500
              puts "🎯 TROUVÉ! #{prime.slug} #{type}: #{montant}€"
            end
          end
        end
      when 'montant_fixe'
        if cat_2_data['montant'] == 1500
          puts "🎯 TROUVÉ! #{prime.slug} montant fixe: #{cat_2_data['montant']}€"
        end
      end
    end
  end
end

puts "\n✅ Diagnostic terminé!"
