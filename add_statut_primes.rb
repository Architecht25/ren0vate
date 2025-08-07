#!/usr/bin/env ruby

# Script temporaire pour ajouter le champ statut_compatible aux primes Bruxelles

# Primes avec double statut (résidentiel + non-résidentiel)
DOUBLE_STATUT_PRIMES = [
  "bruxelles_audit_energetique_maison",
  "bruxelles_audit_energetique_batiment",
  "bruxelles_isolation_thermique_toiture",
  "bruxelles_isolation_interieure_facade",
  "bruxelles_isolation_exterieure_facade",
  "bruxelles_isolation_coulisse",
  "bruxelles_isolation_thermique_sols",
  "bruxelles_remplacement_fenetres_bois",
  "bruxelles_remplacement_fenetres_pvc_alu",
  "bruxelles_reparation_fenetres",
  "bruxelles_pac_chauffage",
  "bruxelles_thermostat",
  "bruxelles_vannes_thermostatiques",
  "bruxelles_chauffe_eau_solaire",
  "bruxelles_raccordement_reseau_chaleur",
  "bruxelles_ventilation_systeme_d"
]

file_path = "/home/obinduarc/code/Architecht25/ren0vate/db/seeds/bruxelles/primes.rb"

puts "🔄 Lecture du fichier primes.rb..."
content = File.read(file_path)

puts "� Traitement des primes..."

# Rechercher tous les blocs Prime.find_or_initialize_by
primes_treated = 0

content.gsub!(/Prime\.find_or_initialize_by\(slug: "([^"]+)"\)\.update!\(.*?\n  image: "([^"]+)",\n  region: "bruxelles",\n  category_id: [^\n]+\n\)/m) do |match|
  slug = $1

  # Vérifier si le statut_compatible est déjà présent
  if match.include?("statut_compatible:")
    match # Garder tel quel si déjà présent
  else
    # Déterminer le statut compatible
    if DOUBLE_STATUT_PRIMES.include?(slug)
      statut = '["residentiel", "non_residentiel"]'
      puts "✅ #{slug} -> Double statut"
    else
      statut = '["residentiel"]'
      puts "➡️  #{slug} -> Résidentiel uniquement"
    end

    # Ajouter le champ statut_compatible avant l'image
    match.gsub(/(\n  .*?),(\n  image: ".*?",)/, "\\1,\n  statut_compatible: #{statut},\\2")
  end

  primes_treated += 1
end

puts "\n💾 Écriture du fichier modifié..."
File.write(file_path, content)

puts "\n🎉 Modification terminée !"
puts "📊 #{primes_treated} primes traitées"
puts "🔧 #{DOUBLE_STATUT_PRIMES.size} primes avec double statut"
