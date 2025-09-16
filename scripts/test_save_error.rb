#!/usr/bin/env ruby

require_relative '../config/environment'

puts "🔧 Test de sauvegarde simulation 70..."

begin
  sim = Simulation.find(70)
  puts "📊 Simulation trouvée: #{sim.id}"

  # Test 1: Créer l'updater
  puts "🔧 Création du service..."
  updater = SimulationPrimesUpdater.new(sim)
  puts "✅ Service créé"

  # Test 2: Appeler la méthode
  puts "🔧 Appel update_user_inputs..."
  user_inputs = {"ramen_deuren" => "15"}
  puts "📝 Inputs: #{user_inputs}"

  result = updater.update_user_inputs(user_inputs)
  puts "✅ Méthode appelée"
  puts "📊 Résultat: #{result}"

rescue => e
  puts "❌ ERREUR: #{e.message}"
  puts "📍 Classe: #{e.class}"
  puts "🔍 Backtrace:"
  e.backtrace.first(10).each { |line| puts "  #{line}" }
end

puts "✅ Test terminé!"
