#!/usr/bin/env ruby
# Script final de vérification de la persistance

require_relative '../config/environment'

class FinalPersistenceTest
  def run_complete_test
    puts "🎯 TEST FINAL DE PERSISTANCE DES SIMULATIONS"
    puts "=" * 60

    # Test 1: Vérifier toutes les simulations existantes
    test_all_existing_simulations

    # Test 2: Créer une nouvelle simulation et tester le workflow complet
    test_new_simulation_workflow

    # Test 3: Vérifier la restauration spécifique pour chaque région
    test_region_specific_restoration

    puts "\n🎉 TOUS LES TESTS DE PERSISTANCE TERMINÉS"
  end

  private

  def test_all_existing_simulations
    puts "\n1️⃣ VÉRIFICATION des simulations existantes..."

    simulations = Simulation.order(:id)
    working_count = 0
    total_amount = 0

    simulations.each do |sim|
      if sim.total_simule && sim.total_simule > 0
        puts "   ✅ Simulation #{sim.id} (#{sim.region}): #{sim.total_simule}€"
        working_count += 1
        total_amount += sim.total_simule

        # Vérifier la cohérence des paramètres
        if sim.parameters.present?
          params_data = JSON.parse(sim.parameters)
          input_count = count_user_inputs(params_data)
          puts "       📝 #{input_count} saisies utilisateur sauvegardées"
        end
      else
        puts "   ❌ Simulation #{sim.id} (#{sim.region}): vide"
      end
    end

    puts "\n   📊 Résumé: #{working_count}/#{simulations.count} simulations avec données"
    puts "   💰 Total cumulé: #{total_amount.round(2)}€"
  end

  def test_new_simulation_workflow
    puts "\n2️⃣ TEST workflow nouvelle simulation..."

    # Créer une simulation test
    test_user = User.first
    test_property = Property.first

    new_sim = Simulation.create!(
      user: test_user,
      property: test_property,
      titre: "Test Final #{Time.current.strftime('%H:%M:%S')}",
      region: "wallonie",
      eligible: true,
      category: "R2"
    )

    puts "   ✅ Nouvelle simulation créée: #{new_sim.id}"

    # Tester la sauvegarde
    test_inputs = {
      'wallonie_toiture_isolation_thermique' => '100',
      'wallonie_realisation_audit_logement' => '1'
    }

    updater = SimulationPrimesUpdater.new(new_sim)
    result = updater.update_user_inputs(test_inputs)

    if result[:success]
      puts "   ✅ Sauvegarde réussie: #{result[:total_amount]}€"

      # Vérifier la persistance
      new_sim.reload
      if new_sim.total_simule == result[:total_amount]
        puts "   ✅ Persistance vérifiée en base"
      else
        puts "   ❌ Problème de persistance"
      end
    else
      puts "   ❌ Échec sauvegarde: #{result[:error]}"
    end
  end

  def test_region_specific_restoration
    puts "\n3️⃣ TEST restauration par région..."

    regions_test = {
      'wallonie' => 'wallonie_toiture_isolation_thermique',
      'flandre' => 'isolation_toiture',
      'bruxelles' => 'bruxelles_isolation_toiture'
    }

    regions_test.each do |region, sample_slug|
      sims_in_region = Simulation.where(region: region).where('total_simule > 0')

      if sims_in_region.any?
        sim = sims_in_region.first
        puts "   🔍 Test #{region} avec simulation #{sim.id}:"

        if sim.parameters.present?
          params_data = JSON.parse(sim.parameters)
          user_inputs = extract_user_inputs(params_data)

          puts "       📝 #{user_inputs.size} saisies trouvées"
          user_inputs.first(3).each do |slug, value|
            puts "         #{slug}: #{value}"
          end
        else
          puts "       ❌ Aucun paramètre trouvé"
        end
      else
        puts "   ⚠️  Aucune simulation #{region} avec données"
      end
    end
  end

  def count_user_inputs(params_data)
    count = 0
    if params_data['prime_cards'].present?
      params_data['prime_cards'].each do |_, category_data|
        next unless category_data['primes']
        category_data['primes'].each do |prime|
          if prime['user_input_value'].present? && prime['user_input_value'] != 0 && prime['user_input_value'] != "0"
            count += 1
          end
        end
      end
    end
    count
  end

  def extract_user_inputs(params_data)
    inputs = {}
    if params_data['prime_cards'].present?
      params_data['prime_cards'].each do |_, category_data|
        next unless category_data['primes']
        category_data['primes'].each do |prime|
          if prime['user_input_value'].present? && prime['user_input_value'] != 0 && prime['user_input_value'] != "0"
            inputs[prime['slug']] = prime['user_input_value']
          end
        end
      end
    end
    inputs
  end
end

# Exécuter le test final
if __FILE__ == $0
  tester = FinalPersistenceTest.new
  tester.run_complete_test
end
