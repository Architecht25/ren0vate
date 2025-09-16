#!/usr/bin/env ruby

puts "🔧 Test reproduction de la requête JavaScript..."

# Simuler exactement ce que le JavaScript envoie
sim_id = 70
user_inputs = {"ramen_deuren" => "15"}

puts "📝 Test avec simulation #{sim_id} et inputs: #{user_inputs.inspect}"

# Tester via le service directement
puts "🔧 Test via service direct..."
begin
  sim = Simulation.find(sim_id)
  updater = SimulationPrimesUpdater.new(sim)
  result = updater.update_user_inputs(user_inputs)
  puts "✅ Service direct: #{result[:success] ? 'Succès' : 'Échec - ' + result[:error]}"
rescue => e
  puts "❌ Service direct failed: #{e.message}"
end

# Tester en simulant les params Rails
puts "🔧 Test avec simulation params Rails..."
begin
  # Simuler ActionController::Parameters
  require 'action_controller'

  # Créer des params comme le ferait Rails
  params_hash = {
    "id" => sim_id.to_s,
    "user_inputs" => user_inputs
  }

  # Convertir en ActionController::Parameters
  params = ActionController::Parameters.new(params_hash)

  # Traiter comme dans le contrôleur
  permitted_inputs = params.require(:user_inputs).permit!.to_h
  puts "📝 Permitted inputs: #{permitted_inputs.inspect}"
  puts "📝 Permitted inputs class: #{permitted_inputs.class}"

  # Tester avec ces inputs
  sim = Simulation.find(sim_id)
  updater = SimulationPrimesUpdater.new(sim)
  result = updater.update_user_inputs(permitted_inputs)
  puts "✅ Avec params Rails: #{result[:success] ? 'Succès' : 'Échec - ' + result[:error]}"

rescue => e
  puts "❌ Avec params Rails failed: #{e.message}"
  puts "📍 Backtrace:"
  puts e.backtrace[0..3].join("\n")
end

puts "✅ Test terminé!"
