#!/usr/bin/env ruby

# Script pour ajouter automatiquement tous les data-slug manquants dans toutes les cartes Bruxelles

require 'fileutils'

puts "🔧 Ajout automatique des data-slug manquants pour toutes les cartes Bruxelles"

# Mapping des inputs vers leurs data-slug
INPUT_TO_SLUG_MAPPING = {
  # Carte Z - Section bonus
  'bruxelles_bonus_z1' => 'bruxelles_bonus_z1',
  'bruxelles_bonus_z2' => 'bruxelles_bonus_z2',
  'bruxelles_bonus_z3' => 'bruxelles_bonus_z3',
  'bruxelles_bonus_z4' => 'bruxelles_bonus_z4',
  'bruxelles_bonus_z5' => 'bruxelles_bonus_z5',
  'bruxelles_bonus_z6' => 'bruxelles_bonus_z6',
  'bruxelles_bonus_z7' => 'bruxelles_bonus_z7',
  'bruxelles_bonus_z9' => 'bruxelles_bonus_z9',
  'bruxelles_bonus_z10' => 'bruxelles_bonus_z10',

  # Carte E - Toiture
  'inputStructureToiture' => 'bruxelles_structure_toiture',
  'inputIsolationThermiqueToiture' => 'bruxelles_isolation_thermique_toiture',
  'inputCouvertureEtancheite' => 'bruxelles_couverture_etancheite',
  'inputIsolationToitureEtancheite' => 'bruxelles_isolation_toiture_etancheite',
  'inputAccessoiresToiture' => 'bruxelles_accessoires_toiture',
  'inputToitureVegetale' => 'bruxelles_toiture_vegetale',

  # Carte F - Façades
  'inputIsolationExterieureFacade' => 'bruxelles_isolation_exterieure_facade',
  'inputIsolationInterieureFacade' => 'bruxelles_isolation_interieure_facade',
  'inputIsolationCoulisse' => 'bruxelles_isolation_coulisse',
  'inputBardageFacade' => 'bruxelles_bardage_facade',
  'inputEnduitFacade' => 'bruxelles_enduit_facade',
  'inputEmbellissementFacadeAvant' => 'bruxelles_embellissement_facade_avant',
  'inputFacadesArriereLatetales' => 'bruxelles_facades_arriere_laterales',

  # Carte J - Chauffage
  'inputPacChauffage' => 'bruxelles_pac_chauffage',
  'inputChauffeEauPac' => 'bruxelles_chauffe_eau_pac',
  'inputChauffeEauSolaire' => 'bruxelles_chauffe_eau_solaire',
  'inputRaccordementReseauChaleur' => 'bruxelles_raccordement_reseau_chaleur',
  'inputRadiateursBassetemp' => 'bruxelles_radiateurs_basse_temperature',
  'inputThermostat' => 'bruxelles_thermostat',
  'inputVannesThermostatiques' => 'bruxelles_vannes_thermostatiques',

  # Carte KL - Sanitaires/électricité
  'inputMiseNormesElectriciteGaz' => 'bruxelles_mise_normes_electricite_gaz',
  'inputAppareilSanitaire' => 'bruxelles_appareil_sanitaire'
}

def process_carte_z_bonus
  puts "\n📝 Traitement spécial de la carte Z (section bonus)..."
  file_path = 'app/views/simulations/partials_bruxelles/cartes/_carte_z_section_bonus.erb'

  return unless File.exist?(file_path)

  content = File.read(file_path)
  original_content = content.dup

  # Pour chaque bonus Z1 à Z10, ajouter le data-slug correspondant
  bonus_mappings = {
    'bruxelles_bonus_z1' => 'bruxelles_bonus_z1',
    'bruxelles_bonus_z2' => 'bruxelles_bonus_z2',
    'bruxelles_bonus_z3' => 'bruxelles_bonus_z3',
    'bruxelles_bonus_z4' => 'bruxelles_bonus_z4',
    'bruxelles_bonus_z5' => 'bruxelles_bonus_z5',
    'bruxelles_bonus_z6' => 'bruxelles_bonus_z6',
    'bruxelles_bonus_z7' => 'bruxelles_bonus_z7',
    'bruxelles_bonus_z9' => 'bruxelles_bonus_z9',
    'bruxelles_bonus_z10' => 'bruxelles_bonus_z10'
  }

  bonus_mappings.each do |card_slug, data_slug|
    # Chercher les sections qui ont ce card-slug-value et ajouter data-slug aux inputs
    content.gsub!(/(\s+data-bruxelles-simulation-card-slug-value="#{card_slug}"[\s\S]*?<input[^>]*data-bruxelles-simulation-card-target="[^"]*"[^>]*)(data-action="[^"]*")/) do |match|
      before_action = $1
      action_part = $2

      # Vérifier si data-slug est déjà présent
      if before_action.include?('data-slug=')
        match # Pas de changement si déjà présent
      else
        # Ajouter data-slug avant data-action
        "#{before_action}data-slug=\"#{data_slug}\"\n                           #{action_part}"
      end
    end
  end

  if content != original_content
    File.write(file_path, content)
    puts "  ✅ Carte Z bonus mise à jour avec succès"
  else
    puts "  ℹ️  Carte Z bonus déjà à jour"
  end
end

def process_regular_cards
  cards_to_process = [
    'app/views/simulations/partials_bruxelles/cartes/_carte_e_toiture.erb',
    'app/views/simulations/partials_bruxelles/cartes/_carte_f_facades.erb',
    'app/views/simulations/partials_bruxelles/cartes/_carte_j_chauffage_eau_chaude.erb',
    'app/views/simulations/partials_bruxelles/cartes/_carte_kl_sanitaires_electricite.erb'
  ]

  cards_to_process.each do |file_path|
    next unless File.exist?(file_path)

    puts "\n📝 Traitement de #{File.basename(file_path)}..."

    content = File.read(file_path)
    original_content = content.dup

    # Ajouter data-slug pour tous les inputs qui n'en ont pas
    INPUT_TO_SLUG_MAPPING.each do |target_name, slug|
      # Pattern pour trouver les inputs avec ce target mais sans data-slug
      pattern = /(\s+data-bruxelles-simulation-card-target="#{target_name}"[^>]*)(data-action="[^"]*")/

      content.gsub!(pattern) do |match|
        before_action = $1
        action_part = $2

        # Vérifier si data-slug est déjà présent
        if before_action.include?('data-slug=')
          match # Pas de changement
        else
          # Ajouter data-slug
          "#{before_action}data-slug=\"#{slug}\"\n                   #{action_part}"
        end
      end
    end

    if content != original_content
      File.write(file_path, content)
      puts "  ✅ #{File.basename(file_path)} mis à jour avec succès"
    else
      puts "  ℹ️  #{File.basename(file_path)} déjà à jour"
    end
  end
end

# Exécuter les traitements
process_carte_z_bonus
process_regular_cards

puts "\n✅ Traitement terminé!"
puts "🔍 Vérification des inputs restants sans data-slug..."

# Vérifier le résultat
remaining = `grep -r "data-action.*calculate" app/views/simulations/partials_bruxelles/cartes/ | grep -v "data-slug=" | wc -l`.strip.to_i
puts "📊 Inputs restants sans data-slug: #{remaining}"

if remaining == 0
  puts "🎉 Tous les inputs ont maintenant leur data-slug!"
else
  puts "⚠️  Il reste encore #{remaining} inputs à traiter manuellement"
end
