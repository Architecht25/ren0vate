#!/usr/bin/env ruby

require_relative '../config/environment'

puts "🔧 Mise à jour forcée simulation 70 avec 25m²..."

sim = Simulation.find(70)
puts "📊 État avant:"
puts "  - Total: #{sim.total_simule}€"

# Forcer la mise à jour avec 25m²
updater = SimulationPrimesUpdater.new(sim)
result = updater.update_user_inputs({"ramen_deuren" => "25"})

puts "📊 Résultat du service:"
puts "  - Succès: #{result[:success]}"
puts "  - Total calculé: #{result[:total_amount]}€"
puts "  - Catégorie utilisée: #{result[:category_used]}"

# Vérifier en base
sim.reload
puts "📊 État après:"
puts "  - Total en DB: #{sim.total_simule}€"

# Analyser les détails
if result[:updated_cards] && result[:updated_cards]["general"]
  general = result[:updated_cards]["general"]
  if general["primes"]
    general["primes"].each do |prime|
      if prime["slug"] == "ramen_deuren"
        puts "🏠 Détails ramen_deuren:"
        puts "  - Input: #{prime['user_input_value']}"
        puts "  - Montant: #{prime['calculated_amount']}€"
      end
    end
  end
end

puts "✅ Mise à jour terminée!"
