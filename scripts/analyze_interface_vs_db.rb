#!/usr/bin/env ruby

puts "🔍 ANALYSE: Interface 2664€ vs DB 4164€"

sim = Simulation.find(70)
puts "📊 Simulation: #{sim.id}"

# Calculer ce que DEVRAIT être le total selon les inputs utilisateur
puts "\n🎯 CALCUL ATTENDU:"
puts "• Isolation toiture: 100m² × 16€/m² = 1600€"
puts "• Isolation murs creux: 200m² × 22.5€/m² = 4500€ (max 100m²) = 2250€"
puts "• Chauffe-eau: 1256€ → ?"

# Vérifier le calcul du chauffe-eau
prime_chauffe_eau = Prime.find_by(slug: 'warmtepompboiler', region: 'flandre')
if prime_chauffe_eau && prime_chauffe_eau.valeurs_par_categorie.is_a?(Hash)
  cat_2_data = prime_chauffe_eau.valeurs_par_categorie['2']
  if cat_2_data
    puts "• Chauffe-eau data cat 2: #{cat_2_data.inspect}"

    # Calculer manuellement
    if cat_2_data['type'] == 'forfait_et_plafond_facture'
      forfait = cat_2_data['forfait'] || 0
      plafond_pct = cat_2_data['plafond_pourcentage'] || 0

      if plafond_pct > 0
        plafond_montant = 1256 * (plafond_pct / 100.0)
        montant_final = [forfait, plafond_montant].min
        puts "• Chauffe-eau: min(forfait=#{forfait}€, #{plafond_pct}% × 1256€ = #{plafond_montant}€) = #{montant_final}€"
      else
        puts "• Chauffe-eau: forfait = #{forfait}€"
      end
    end
  end
end

puts "🎯 TOTAL ATTENDU: 1600 + 2250 + ~314 = ~4164€"
puts "🤔 Donc la sauvegarde semble CORRECTE!"

# Analyser ce qui est vraiment sauvé
if sim.parameters.present?
  params = JSON.parse(sim.parameters)
  puts "\n📋 DÉTAIL SAUVEGARDE ACTUELLE:"

  if params["prime_cards"]
    params["prime_cards"].each do |category_key, category_data|
      puts "\n📁 #{category_key.upcase}: #{category_data['total']}€"

      if category_data["primes"]
        category_data["primes"].each do |prime|
          input_val = prime['user_input_value'] || '0'
          calc_amount = prime['calculated_amount'] || 0
          if calc_amount.to_f > 0
            puts "  ✅ #{prime['slug']}: input=#{input_val} → calculé=#{calc_amount}€"
          end
        end
      end
    end
  end
end

puts "\n🤔 HYPOTHÈSE:"
puts "Le problème pourrait être que l'INTERFACE JavaScript"
puts "calcule différemment que le backend Ruby."
puts ""
puts "Interface: 2664€ (calcul JS incorrect?)"
puts "Backend:   4164€ (calcul Ruby correct?)"

puts "\n💡 VÉRIFICATION NÉCESSAIRE:"
puts "1. L'interface affiche-t-elle bien les bons montants par carte?"
puts "2. L'interface additionne-t-elle correctement?"
puts "3. Y a-t-il des primes cachées/fantômes?"

puts "\n✅ Analyse terminée!"
