#!/usr/bin/env ruby
# Script pour peupler toutes les simulations avec des données de test

require_relative '../config/environment'

class SimulationPopulator
  def initialize
    @logger = Rails.logger
  end

  def populate_all_simulations
    simulations = Simulation.all.order(:id)

    puts "🏠 Population de #{simulations.count} simulations avec des données de test"
    puts "=" * 60

    simulations.each_with_index do |simulation, index|
      populate_simulation(simulation, index)
    end

    puts "\n✅ Population terminée pour #{simulations.count} simulations"
  end

  private

  def populate_simulation(simulation, index)
    puts "\n🔧 Simulation #{simulation.id}: #{simulation.titre}"
    puts "   Région: #{simulation.region}"

    # Forcer l'éligibilité si nécessaire
    unless simulation.eligible?
      simulation.update!(
        eligible: true,
        category: determine_category_for_region(simulation.region),
        category_description: "Catégorie simulée pour test"
      )
      puts "   ✅ Éligibilité forcée"
    end

    # Générer des données selon la région
    test_data = generate_test_data_for_region(simulation.region, index)

    if test_data.any?
      puts "   📝 Injection de #{test_data.keys.length} saisies utilisateur..."

      # Utiliser le service mis à jour pour sauvegarder
      updater = SimulationPrimesUpdater.new(simulation)
      result = updater.update_user_inputs(test_data)

      if result[:success]
        puts "   ✅ Données sauvegardées: #{result[:total_amount]}€"
      else
        puts "   ❌ Erreur: #{result[:error]}"
      end
    else
      puts "   ⚠️  Aucune donnée de test disponible pour cette région"
    end
  end

  def determine_category_for_region(region)
    case region&.downcase
    when 'wallonie'
      ['R1', 'R2', 'R3'].sample
    when 'flandre'
      ['1', '2', '3'].sample
    when 'bruxelles'
      ['A', 'B', 'C'].sample
    else
      'R2' # Par défaut
    end
  end

  def generate_test_data_for_region(region, index)
    case region&.downcase
    when 'wallonie'
      generate_wallonie_test_data(index)
    when 'flandre'
      generate_flandre_test_data(index)
    when 'bruxelles'
      generate_bruxelles_test_data(index)
    else
      {}
    end
  end

  def generate_wallonie_test_data(index)
    # Données de test variées pour Wallonie
    base_data = {
      'wallonie_realisation_audit_logement' => '1',
      'wallonie_toiture_isolation_thermique' => (50 + index * 25).to_s,
      'wallonie_isolation_sols' => (30 + index * 15).to_s,
      'wallonie_menuiseries_vitrages' => (index % 2 == 0 ? '1' : '0')
    }

    # Ajouter des variations selon l'index
    case index % 4
    when 0
      base_data.merge({
        'wallonie_toiture_remplacement_couverture' => '1',
        'wallonie_installation_electrique' => '1'
      })
    when 1
      base_data.merge({
        'wallonie_toiture_appropriation_charpente' => '1',
        'wallonie_isolation_sols_biosource' => (20 + index * 10).to_s
      })
    when 2
      base_data.merge({
        'wallonie_toiture_evacuation_eaux_pluviales' => '1',
        'wallonie_installation_gaz' => '1'
      })
    else
      base_data.merge({
        'wallonie_remplacement_supports_circulation' => (10 + index * 5).to_s,
        'wallonie_isolation_finition_planchers' => (15 + index * 8).to_s
      })
    end
  end

  def generate_flandre_test_data(index)
    # Données de test pour Flandre avec les vrais slugs
    base_data = {
      'isolation_toiture' => (60 + index * 20).to_s,
      'isolation_murs_cat12' => (40 + index * 15).to_s,
      'isolation_sol' => (25 + index * 12).to_s
    }

    # Variations selon l'index
    case index % 3
    when 0
      base_data.merge({
        'ramen_deuren' => '1',
        'warmtepomp' => '1'
      })
    when 1
      base_data.merge({
        'voorbereiding_isolatie' => '1',
        'warmtepompboiler' => '1'
      })
    else
      base_data.merge({
        'renovation_toiture' => '1',
        'voorbereiding_sanitair_elec' => '1'
      })
    end
  end

  def generate_bruxelles_test_data(index)
    # Données de test pour Bruxelles
    base_data = {
      'bruxelles_isolation_toiture' => (70 + index * 25).to_s,
      'bruxelles_isolation_facades' => (45 + index * 18).to_s,
      'bruxelles_isolation_sol' => (30 + index * 10).to_s
    }

    # Variations selon l'index
    case index % 4
    when 0
      base_data.merge({
        'bruxelles_chassis_performants' => '1',
        'bruxelles_ventilation_double_flux' => '1'
      })
    when 1
      base_data.merge({
        'bruxelles_pompe_chaleur' => '1',
        'bruxelles_audit_energetique' => '1'
      })
    when 2
      base_data.merge({
        'bruxelles_chaudiere_condensation' => '1',
        'bruxelles_panneaux_solaires' => '1'
      })
    else
      base_data.merge({
        'bruxelles_isolation_biosourcee' => (20 + index * 8).to_s,
        'bruxelles_systeme_regulation' => '1'
      })
    end
  end
end

# Exécuter le script
if __FILE__ == $0
  populator = SimulationPopulator.new
  populator.populate_all_simulations
end
