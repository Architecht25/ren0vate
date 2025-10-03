#!/usr/bin/env ruby

# Script pour mettre à jour automatiquement tous les data-slug manquants dans les cartes Bruxelles

require 'fileutils'

puts "🔧 Début de la mise à jour des data-slug pour les cartes Bruxelles"

# Mapping des cartes vers leurs primes principales
CARD_PRIME_MAPPING = {
  '_carte_d_humidite_nuisibles.erb' => [
    'bruxelles_traitement_humidite_sol',
    'bruxelles_traitement_fongique_insectes'
  ],
  '_carte_e_toiture.erb' => [
    'bruxelles_structure_toiture',
    'bruxelles_isolation_thermique_toiture',
    'bruxelles_couverture_etancheite',
    'bruxelles_isolation_toiture_etancheite',
    'bruxelles_accessoires_toiture',
    'bruxelles_toiture_vegetale'
  ],
  '_carte_f_facades.erb' => [
    'bruxelles_isolation_exterieure_facade',
    'bruxelles_isolation_interieure_facade',
    'bruxelles_isolation_coulisse',
    'bruxelles_bardage_facade',
    'bruxelles_enduit_facade',
    'bruxelles_embellissement_facade_avant',
    'bruxelles_facades_arriere_laterales'
  ],
  '_carte_g_portes_fenetres.erb' => [
    'bruxelles_remplacement_fenetres_pvc_alu',
    'bruxelles_remplacement_fenetres_bois',
    'bruxelles_reparation_fenetres',
    'bruxelles_reparation_portes'
  ],
  '_carte_h_sols_planchers.erb' => [
    'bruxelles_isolation_thermique_sols',
    'bruxelles_isolation_acoustique_sols',
    'bruxelles_escaliers'
  ],
  '_carte_i_amenagement_equipements.erb' => [
    'bruxelles_amenagement_pmr',
    'bruxelles_appareil_sanitaire',
    'bruxelles_emplacement_velo'
  ],
  '_carte_j_chauffage_eau_chaude.erb' => [
    'bruxelles_pac_chauffage',
    'bruxelles_chauffe_eau_pac',
    'bruxelles_chauffe_eau_solaire',
    'bruxelles_raccordement_reseau_chaleur',
    'bruxelles_radiateurs_basse_temperature',
    'bruxelles_thermostat',
    'bruxelles_vannes_thermostatiques'
  ],
  '_carte_kl_sanitaires_electricite.erb' => [
    'bruxelles_mise_normes_electricite_gaz',
    'bruxelles_protection_incendie'
  ],
  '_carte_m_ventilation.erb' => [
    'bruxelles_ventilation_systeme_c',
    'bruxelles_ventilation_systeme_d'
  ],
  '_carte_z_section_bonus.erb' => [
    'bruxelles_bonus_z1',
    'bruxelles_bonus_z2',
    'bruxelles_bonus_z3',
    'bruxelles_bonus_z4',
    'bruxelles_bonus_z5',
    'bruxelles_bonus_z6',
    'bruxelles_bonus_z7',
    'bruxelles_bonus_z9',
    'bruxelles_bonus_z10'
  ]
}

# Patterns à rechercher pour identifier les inputs sans data-slug
INPUT_PATTERNS = [
  /data-action="[^"]*calculate"[^>]*>/,
  /data-action='[^']*calculate'[^>]*>/
]

cards_dir = 'app/views/simulations/partials_bruxelles/cartes'

# Parcourir chaque carte
CARD_PRIME_MAPPING.each do |card_file, prime_slugs|
  card_path = File.join(cards_dir, card_file)

  next unless File.exist?(card_path)

  puts "\n📝 Traitement de #{card_file}..."

  content = File.read(card_path)
  original_content = content.dup
  modified = false

  # Pour chaque prime slug de cette carte
  prime_slugs.each do |prime_slug|
    # Chercher les patterns d'input sans data-slug qui pourraient correspondre à cette prime
    input_lines = content.lines.each_with_index.select do |line, index|
      line.match?(/data-action="[^"]*calculate"/) && !line.match?(/data-slug=/)
    end

    if input_lines.any?
      puts "  🔍 Trouvé #{input_lines.length} input(s) sans data-slug"
      puts "  ✅ Primes disponibles: #{prime_slugs.join(', ')}"
    end
  end

  puts "  ⚠️  Mise à jour manuelle requise pour #{card_file}"
end

puts "\n✅ Analyse terminée. Mise à jour manuelle recommandée pour chaque carte."
puts "💡 Utilisez les mappings ci-dessus pour ajouter les data-slug appropriés."
