#!/usr/bin/env ruby

# Script pour extraire les cartes individuelles du fichier cartes_primes_import.html.erb

require 'fileutils'

# Lire le fichier source
source_file = '/home/obinduarc/code/Architecht25/ren0vate/app/views/simulations/partials_flandre/_cartes_primes_import.html.erb'
content = File.read(source_file)

# Répertoire de destination
cards_dir = '/home/obinduarc/code/Architecht25/ren0vate/app/views/simulations/partials_flandre/cards'

# Liste des slugs des cartes
card_slugs = [
  'isolation_toiture',
  'isolation_murs_cat12',
  'isolation_murs_cat34',
  'isolation_sol',
  'ramen_deuren',
  'warmtepomp',
  'warmtepompboiler',
  'voorbereiding_isolatie',
  'voorbereiding_sanitair_elec',
  'renovation_toiture',
  'renovation_murs',
  'renovation_sol'
]

card_slugs.each do |slug|
  puts "Extraction de la carte: #{slug}"

  # Pattern pour matcher la carte complète
  pattern = /<!-- Carte:.*?#{slug.gsub('_', '.*?')}.*?-->(.*?)(?=<!-- Carte:|<!-- End of|$)/m

  # Plus simple: chercher par data-slug-value
  slug_pattern = /data-flandre-prime-card-slug-value="#{slug}"(.*?)(?=<div class="col-lg-2|<\/div>\s*<\/div>\s*<\/div>\s*<!-- Section)/m

  if match = content.match(/<!-- Carte:.*?-->\s*<div class="col-lg-2.*?data-flandre-prime-card-slug-value="#{slug}".*?<\/div>\s*<\/div>\s*<\/div>/m)
    card_content = match[0].gsub(/^\s*<!-- Carte:.*?-->\s*/, '')

    # Créer le fichier
    File.open("#{cards_dir}/_#{slug}.html.erb", 'w') do |f|
      f.write(card_content)
    end

    puts "✅ Carte #{slug} extraite"
  else
    puts "❌ Carte #{slug} non trouvée"
  end
end

puts "✅ Extraction terminée!"
