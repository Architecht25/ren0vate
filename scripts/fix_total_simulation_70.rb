#!/usr/bin/env ruby

require_relative '../config/environment'

puts "🔧 Correction forcée du total de la simulation 70..."

sim = Simulation.find(70)
puts "📊 État actuel:"
puts "  - Total simulé: #{sim.total_simule}€"

# Analyser les paramètres actuels
if sim.parameters.present?
  params = JSON.parse(sim.parameters)
  puts "  - Total dans params: #{params['total_general']}€"

  # Recalculer manuellement le total
  total_reel = 0
  if params['prime_cards'] && params['prime_cards']['general'] && params['prime_cards']['general']['primes']
    params['prime_cards']['general']['primes'].each do |prime|
      montant = prime['calculated_amount'].to_f
      total_reel += montant
      puts "  - Prime #{prime['slug']}: #{montant}€"
    end
  end

  puts "📊 Total recalculé: #{total_reel}€"

  # Forcer la mise à jour
  if total_reel > 0 && total_reel != sim.total_simule
    puts "🔧 Mise à jour forcée..."
    sim.update!(total_simule: total_reel)
    puts "✅ Total corrigé: #{total_reel}€"
  else
    puts "⚠️ Aucune correction nécessaire ou total nul"
  end
else
  puts "❌ Pas de paramètres trouvés"
end

puts "✅ Script terminé!"
