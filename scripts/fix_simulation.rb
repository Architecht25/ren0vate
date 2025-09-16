#!/usr/bin/env ruby
# Script pour forcer le calcul des primes pour les simulations bloquées

require_relative '../config/environment'

class SimulationFixer
  def initialize
    @logger = Rails.logger
  end

  def fix_simulation(simulation_id)
    simulation = Simulation.find(simulation_id)

    puts "🔧 Correction de la simulation #{simulation_id}"
    puts "   Titre: #{simulation.titre}"
    puts "   Région: #{simulation.region}"
    puts "   Étape actuelle: #{simulation.processing_step} (#{simulation.step_name})"

    # Forcer l'éligibilité pour les tests
    unless simulation.eligible?
      puts "   ⚠️  Simulation non éligible, forçage de l'éligibilité..."
      simulation.update!(
        eligible: true,
        category: "R2", # Catégorie par défaut pour test
        category_description: "Catégorie forcée pour test"
      )
      puts "   ✅ Éligibilité forcée"
    end

    # Déclencher le calcul des primes
    if simulation.category.present? && simulation.parameters.present?
      params_data = JSON.parse(simulation.parameters)
      if params_data["prime_cards"].empty?
        puts "   🔄 Déclenchement du calcul des primes..."
        force_prime_calculation(simulation)
      else
        puts "   ✅ Primes déjà calculées"
      end
    end

    simulation.reload
    puts "   📊 Résultat final: #{simulation.total_simule}€"
  end

  private

  def force_prime_calculation(simulation)
    # Utiliser le même système que le contrôleur
    controller_instance = SimulationsController.new
    controller_instance.instance_variable_set(:@simulation, simulation)

    # Simuler current_user (prendre le propriétaire de la simulation)
    controller_instance.define_singleton_method(:current_user) { simulation.user }

    # Appeler la méthode privée
    controller_instance.send(:perform_primes_calculation, simulation)

    puts "   ✅ Calcul des primes forcé"
  rescue => e
    puts "   ❌ Erreur lors du calcul: #{e.message}"
  end
end

# Utilisation du script
if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby scripts/fix_simulation.rb SIMULATION_ID"
    puts "Exemple: ruby scripts/fix_simulation.rb 70"
    exit 1
  end

  simulation_id = ARGV[0].to_i
  fixer = SimulationFixer.new
  fixer.fix_simulation(simulation_id)
end
