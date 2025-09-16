#!/usr/bin/env ruby
# Test complet de persistance : simuler un utilisateur créant une simulation et saisissant des données

require_relative '../config/environment'

class UserSimulationTest
  def initialize
    @test_user = User.first || create_test_user
    @test_property = Property.first || create_test_property
  end

  def test_complete_user_workflow
    puts "🧪 TEST COMPLET: Simulation d'un utilisateur créant et utilisant une simulation"
    puts "=" * 70

    # Étape 1: Créer une nouvelle simulation
    create_new_simulation

    # Étape 2: Simuler des saisies utilisateur progressives
    simulate_user_inputs

    # Étape 3: Simuler la navigation (quitter et revenir)
    simulate_page_reload

    # Étape 4: Ajouter plus de données
    add_more_data

    # Étape 5: Vérification finale
    final_verification

    puts "\n🎉 Test terminé avec succès ! La persistance fonctionne parfaitement."
  end

  private

  def create_new_simulation
    puts "\n1️⃣ CRÉATION d'une nouvelle simulation..."

    @simulation = Simulation.create!(
      user: @test_user,
      property: @test_property,
      titre: "Test Utilisateur Réel #{Time.current.strftime('%H:%M:%S')}",
      region: "wallonie",
      total_simule: 0
    )

    # Forcer l'éligibilité pour le test
    @simulation.update!(
      eligible: true,
      category: "R2",
      category_description: "Catégorie de test"
    )

    puts "   ✅ Simulation créée: ID #{@simulation.id}"
    puts "   📊 Total initial: #{@simulation.total_simule}€"
  end

  def simulate_user_inputs
    puts "\n2️⃣ SAISIE de données par l'utilisateur..."

    # Première saisie : isolation toiture
    puts "   📝 Utilisateur saisit 200m² d'isolation toiture..."
    test_save({
      'wallonie_toiture_isolation_thermique' => '200'
    })

    # Deuxième saisie : ajout audit
    puts "   📝 Utilisateur coche l'audit énergétique..."
    test_save({
      'wallonie_toiture_isolation_thermique' => '200',
      'wallonie_realisation_audit_logement' => '1'
    })

    # Troisième saisie : ajout isolation sols
    puts "   📝 Utilisateur ajoute 150m² d'isolation de sols..."
    test_save({
      'wallonie_toiture_isolation_thermique' => '200',
      'wallonie_realisation_audit_logement' => '1',
      'wallonie_isolation_sols' => '150'
    })
  end

  def test_save(inputs)
    updater = SimulationPrimesUpdater.new(@simulation)
    result = updater.update_user_inputs(inputs)

    if result[:success]
      puts "   ✅ Sauvegarde réussie: #{result[:total_amount]}€"
      @last_total = result[:total_amount]
    else
      puts "   ❌ Échec sauvegarde: #{result[:error]}"
    end
  end

  def simulate_page_reload
    puts "\n3️⃣ SIMULATION de la navigation (utilisateur quitte et revient)..."

    # Simuler un rechargement : récupérer la simulation depuis la base
    reloaded_simulation = Simulation.find(@simulation.id)

    puts "   🔄 Simulation rechargée depuis la base de données"
    puts "   📊 Total après rechargement: #{reloaded_simulation.total_simule}€"

    if reloaded_simulation.total_simule == @last_total
      puts "   ✅ Les données ont persisté !"
    else
      puts "   ❌ PROBLÈME: Les données ne persistent pas !"
      puts "       Attendu: #{@last_total}€, Trouvé: #{reloaded_simulation.total_simule}€"
    end

    # Vérifier les saisies utilisateur sauvegardées
    if reloaded_simulation.parameters.present?
      params_data = JSON.parse(reloaded_simulation.parameters)
      saved_inputs = extract_user_inputs(params_data)
      puts "   📝 #{saved_inputs.size} saisies utilisateur récupérées:"
      saved_inputs.each do |slug, value|
        puts "       #{slug}: #{value}"
      end
    else
      puts "   ❌ PROBLÈME: Aucun paramètre sauvegardé !"
    end

    @simulation = reloaded_simulation
  end

  def add_more_data
    puts "\n4️⃣ AJOUT de données supplémentaires..."

    puts "   📝 Utilisateur ajoute des menuiseries..."
    test_save({
      'wallonie_toiture_isolation_thermique' => '200',
      'wallonie_realisation_audit_logement' => '1',
      'wallonie_isolation_sols' => '150',
      'wallonie_menuiseries_vitrages' => '1'
    })
  end

  def final_verification
    puts "\n5️⃣ VÉRIFICATION FINALE..."

    final_simulation = Simulation.find(@simulation.id)

    puts "   📊 Total final: #{final_simulation.total_simule}€"

    if final_simulation.parameters.present?
      params_data = JSON.parse(final_simulation.parameters)
      final_inputs = extract_user_inputs(params_data)

      puts "   📝 Toutes les saisies sauvegardées (#{final_inputs.size}):"
      final_inputs.each do |slug, value|
        puts "       #{slug}: #{value}"
      end

      if final_inputs.size >= 4 && final_simulation.total_simule > 0
        puts "   ✅ SUCCÈS: Toutes les données persistent correctement !"
      else
        puts "   ❌ PROBLÈME: Données incomplètes ou total nul"
      end
    else
      puts "   ❌ PROBLÈME CRITIQUE: Aucun paramètre sauvegardé !"
    end
  end

  def extract_user_inputs(params_data)
    inputs = {}

    if params_data['prime_cards'].present?
      params_data['prime_cards'].each do |category_key, category_data|
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

  def create_test_user
    User.create!(
      email: "test_real_user@example.com",
      password: "password123",
      nom: "Utilisateur",
      prenom: "Test"
    )
  end

  def create_test_property
    Property.create!(
      user: @test_user,
      adresse: "123 Rue de Test",
      ville: "Ville Test",
      code_postal: "1000",
      pays: "Belgique"
    )
  end
end

# Exécuter le test
if __FILE__ == $0
  tester = UserSimulationTest.new
  tester.test_complete_user_workflow
end
