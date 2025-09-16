#!/usr/bin/env ruby

puts "🧹 NETTOYAGE DE LA SIMULATION 70"

sim = Simulation.find(70)
puts "📊 Simulation: #{sim.id}"
puts "💾 Total avant nettoyage: #{sim.total_simule}€"

# Créer les bonnes données avec seulement les primes voulues
correct_params = {
  'prime_cards' => {
    'general' => {
      'titre' => 'General',
      'total' => 1914.0,
      'primes' => [
        {
          'slug' => 'isolation_toiture',
          'titre' => 'Isolation de la toiture',
          'user_input_value' => '100',
          'calculated_amount' => 1600.0,
          'category_data' => {
            'type' => 'montant_m2_et_limite',
            'montant_m2' => 16.0,
            'surface_max' => 100.0,
            'plafond_pourcentage' => 25
          }
        },
        {
          'slug' => 'warmtepompboiler',
          'titre' => 'Chauffe-eau thermodynamique',
          'user_input_value' => '1256',
          'calculated_amount' => 314.0,
          'category_data' => {
            'type' => 'forfait_et_plafond_facture',
            'forfait' => 900,
            'plafond_pourcentage' => 25
          }
        }
      ]
    },
    'murs' => {
      'titre' => 'Murs',
      'total' => 2250.0,
      'primes' => [
        {
          'slug' => 'isolation_murs_cat12',
          'titre' => 'Isolation des murs extérieurs (cat. 1-2)',
          'user_input_value' => '200',
          'calculated_amount' => 2250.0,
          'category_data' => {
            'type' => 'montant_variable_m2_et_limite',
            'montants_m2' => {
              'exterieur' => 22.5,
              'interieur' => 15.0,
              'mur_creux' => 7.5
            },
            'surface_max' => 100.0,
            'plafond_pourcentage' => 25
          }
        }
      ]
    }
  },
  'total_general' => 4164.0,
  'total' => 4164.0,
  'category_used' => '2',
  'calculation_timestamp' => Time.current.iso8601
}

puts "\n🔧 Application des données correctes..."
puts "✅ isolation_toiture: 100m² → 1600€"
puts "✅ warmtepompboiler: 1256€ → 314€ (plafond 25%)"
puts "✅ isolation_murs_cat12: 200m² → 2250€ (max 100m²)"
puts "📊 Total correct: 4164€"

begin
  sim.update!(
    parameters: correct_params.to_json,
    total_simule: 4164.0,
    updated_at: Time.current
  )

  sim.reload
  puts "\n✅ NETTOYAGE RÉUSSI!"
  puts "💾 Nouveau total en base: #{sim.total_simule}€"

  # Vérification
  if sim.parameters.present?
    params = JSON.parse(sim.parameters)
    total_verification = 0

    params["prime_cards"].each do |category_key, category_data|
      total_verification += category_data['total'].to_f
      puts "📁 #{category_key}: #{category_data['total']}€"
    end

    puts "📊 Vérification total: #{total_verification}€"

    if total_verification == 4164.0 && sim.total_simule == 4164.0
      puts "🎉 PARFAIT! Simulation nettoyée et cohérente!"
    else
      puts "⚠️ Il reste des incohérences"
    end
  end

rescue => e
  puts "❌ Erreur lors du nettoyage: #{e.message}"
end

puts "\n✅ Nettoyage terminé!"
