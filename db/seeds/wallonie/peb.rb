puts "🔋 Création des certificats PEB Wallonie..."

# Ce fichier pourra contenir les spécificités PEB wallonnes
# À développer selon les standards wallons

# Les certificats PEB en Wallonie ont leurs propres classes :
# A++, A+, A, B, C, D, E, F, G

# Plages de consommation spécifiques à la Wallonie
peb_wallonie_classes = {
  "A++" => { min: 0, max: 15, description: "Très haute performance" },
  "A+" => { min: 16, max: 30, description: "Haute performance" },
  "A" => { min: 31, max: 45, description: "Bonne performance" },
  "B" => { min: 46, max: 85, description: "Performance correcte" },
  "C" => { min: 86, max: 170, description: "Performance moyenne" },
  "D" => { min: 171, max: 255, description: "Performance faible" },
  "E" => { min: 256, max: 340, description: "Mauvaise performance" },
  "F" => { min: 341, max: 425, description: "Très mauvaise performance" },
  "G" => { min: 426, max: 999, description: "Performance très faible" }
}

puts "📊 Classes PEB Wallonie définies :"
peb_wallonie_classes.each do |classe, info|
  puts "  #{classe}: #{info[:min]}-#{info[:max]} kWh/m²/an (#{info[:description]})"
end

puts "✅ Standards PEB Wallonie configurés"
