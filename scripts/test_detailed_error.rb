#!/usr/bin/env ruby

puts "🔧 Test approfondi de l'erreur Hash/String..."

# Charger les données de simulation 70
sim = Simulation.find(70)
puts "📊 Simulation trouvée: #{sim.id}"

# Parser les paramètres actuels
current_params_json = sim.parameters.presence || "{}"
puts "📝 Parameters JSON: #{current_params_json[0..100]}..."

begin
  current_params = JSON.parse(current_params_json)
  puts "✅ Parse JSON réussi"
rescue => e
  puts "❌ Erreur parse JSON: #{e.message}"
  current_params = {}
end

# Tester la conversion JSON des paramètres actuels
begin
  json_test = current_params.to_json
  puts "✅ to_json des paramètres actuels réussi: #{json_test[0..50]}..."
rescue => e
  puts "❌ Erreur to_json paramètres actuels: #{e.message}"
end

# Créer le service et tester l'étape par étape
puts "🔧 Création du service..."
service = SimulationPrimesUpdater.new(sim)

# Tester update_prime_inputs directement
user_inputs = {"ramen_deuren" => "15"}
puts "📝 Test update_prime_inputs avec: #{user_inputs.inspect}"

begin
  # Tester chaque étape individuellement
  puts "🔄 Étape 1: update_prime_inputs"
  updated_params = service.send(:update_prime_inputs, current_params, user_inputs)
  puts "✅ update_prime_inputs réussi"

  puts "🔄 Étape 2: recalculate_amounts"
  service.send(:recalculate_amounts, updated_params)
  puts "✅ recalculate_amounts réussi"

  puts "🔄 Étape 3: Test conversion JSON"
  json_result = updated_params.to_json
  puts "✅ Conversion JSON réussi: #{json_result[0..50]}..."

  puts "🔄 Étape 4: save_to_database"
  service.send(:save_to_database, updated_params)
  puts "✅ save_to_database réussi"

rescue => e
  puts "❌ Erreur détectée: #{e.message}"
  puts "📍 Backtrace:"
  puts e.backtrace[0..5].join("\n")

  # Inspecter l'état des paramètres à ce moment
  puts "🔍 État updated_params:"
  puts updated_params.inspect[0..200] if defined?(updated_params)
end

puts "✅ Test terminé!"
