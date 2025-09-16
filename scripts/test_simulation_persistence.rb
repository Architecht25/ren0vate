#!/usr/bin/env ruby
# Script de test pour vérifier la persistance des données de simulation

require_relative '../config/environment'

class SimulationPersistenceTest
  def initialize
    @test_user = User.first || create_test_user
    @test_property = Property.first || create_test_property
  end

  def run_tests
    puts "🧪 Test de persistance des données de simulation"
    puts "=" * 50

    test_simulation_creation
    test_data_persistence
    test_restoration_after_reload

    puts "\n✅ Tous les tests terminés"
  end

  private

  def test_simulation_creation
    puts "\n1. Test de création de simulation..."

    @simulation = Simulation.create!(
      user: @test_user,
      property: @test_property,
      titre: "Test Persistance #{Time.current.strftime('%H:%M:%S')}",
      region: "wallonie",
      total_simule: 0
    )

    puts "✅ Simulation créée: ID #{@simulation.id}"
  end

  def test_data_persistence
    puts "\n2. Test de sauvegarde des données..."

    # Simuler une saisie utilisateur
    test_inputs = {
      'wallonie_toiture_isolation_thermique' => '150',
      'wallonie_toiture_remplacement_couverture' => '1'
    }

    updater = SimulationPrimesUpdater.new(@simulation)
    result = updater.update_user_inputs(test_inputs)

    if result[:success]
      puts "✅ Données sauvegardées: #{result[:total_amount]}€"
      @expected_total = result[:total_amount]
    else
      puts "❌ Erreur lors de la sauvegarde: #{result[:error]}"
      return false
    end

    # Vérifier en base
    @simulation.reload
    if @simulation.total_simule == @expected_total
      puts "✅ Total en base cohérent: #{@simulation.total_simule}€"
    else
      puts "❌ Total en base incohérent: #{@simulation.total_simule}€ vs #{@expected_total}€"
    end
  end

  def test_restoration_after_reload
    puts "\n3. Test de restauration après rechargement..."

    # Simuler un rechargement de page
    reloaded_simulation = Simulation.find(@simulation.id)

    if reloaded_simulation.total_simule == @expected_total
      puts "✅ Total restauré correctement: #{reloaded_simulation.total_simule}€"
    else
      puts "❌ Total perdu: #{reloaded_simulation.total_simule}€ vs #{@expected_total}€"
    end

    # Vérifier les paramètres JSON
    if reloaded_simulation.parameters.present?
      params_data = JSON.parse(reloaded_simulation.parameters)
      if params_data['prime_cards'].present?
        input_count = 0
        params_data['prime_cards'].each do |_, category_data|
          next unless category_data['primes']
          category_data['primes'].each do |prime|
            if prime['user_input_value'].present? && prime['user_input_value'] != 0
              input_count += 1
            end
          end
        end
        puts "✅ #{input_count} saisies utilisateur sauvegardées"
      else
        puts "❌ Aucune donnée de prime trouvée"
      end
    else
      puts "❌ Paramètres JSON manquants"
    end
  end

  def create_test_user
    User.create!(
      email: "test_persistence@example.com",
      password: "password123",
      nom: "Test",
      prenom: "Persistence"
    )
  end

  def create_test_property
    Property.create!(
      user: @test_user,
      adresse: "Test Address 123",
      ville: "Test City",
      code_postal: "1000",
      pays: "Belgique"
    )
  end
end

# Exécuter le test
if __FILE__ == $0
  tester = SimulationPersistenceTest.new
  tester.run_tests
end
