#!/usr/bin/env ruby

require_relative '../config/environment'

puts "🔍 Diagnostic des calculs pour la simulation 70..."

sim = Simulation.find(70)
puts "📊 Simulation 70:"
puts "  - Category: #{sim.category}"
puts "  - Région: #{sim.region}"

# Récupérer la prime ramen_deuren
prime = Prime.find_by(slug: "ramen_deuren", region: "flandre")
if prime
  puts "\n🏠 Prime ramen_deuren:"
  puts "  - Titre: #{prime.titre}"
  puts "  - Catégories éligibles: #{prime.eligible_categories}"

  valeurs = JSON.parse(prime.valeurs_par_categorie)
  puts "  - Valeurs par catégorie: #{valeurs.keys}"

  if valeurs["2"]
    cat2_data = valeurs["2"]
    puts "\n💰 Données catégorie 2:"
    puts "  - Type: #{cat2_data['type']}"
    puts "  - Montant/m²: #{cat2_data['montant_m2']}€"
    puts "  - Surface max: #{cat2_data['surface_max']}m²"
    puts "  - Plafond %: #{cat2_data['plafond_pourcentage']}%"

    # Calculer manuellement
    surface = 5
    montant_calcule = surface * cat2_data['montant_m2']
    puts "\n🧮 Calcul manuel:"
    puts "  - #{surface}m² × #{cat2_data['montant_m2']}€/m² = #{montant_calcule}€"
  else
    puts "❌ Pas de données pour la catégorie 2"
  end
else
  puts "❌ Prime ramen_deuren non trouvée"
end

# Tester le service avec les vrais paramètres
puts "\n🔧 Test du service SimulationPrimesUpdater..."
user_inputs = { "ramen_deuren" => "5" }

begin
  result = SimulationPrimesUpdater.new(sim).call(user_inputs)
  puts "✅ Service appelé avec succès"
  puts "  - Succès: #{result[:success]}"
  puts "  - Total: #{result[:total_amount]}€"
  puts "  - Catégorie utilisée: #{result[:category_used]}"

  if result[:updated_cards] && result[:updated_cards]["general"]
    general_data = result[:updated_cards]["general"]
    if general_data["primes"]
      general_data["primes"].each do |prime_data|
        if prime_data["slug"] == "ramen_deuren"
          puts "  - Prime ramen_deuren:"
          puts "    * Input: #{prime_data['user_input_value']}"
          puts "    * Montant calculé: #{prime_data['calculated_amount']}€"
          puts "    * Données catégorie: #{prime_data['category_data']}"
        end
      end
    end
  end

rescue => e
  puts "❌ Erreur service: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n✅ Diagnostic terminé!"
