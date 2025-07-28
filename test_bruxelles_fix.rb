#!/usr/bin/env ruby

puts "🔍 Vérification des corrections pour le système Bruxelles..."

# Vérifier que les fichiers existent et contiennent les bonnes corrections
files_to_check = [
  {
    path: 'app/controllers/pages_controller.rb',
    check: 'needs_refinement = profile_type == \'particulier\'',
    description: 'Logique needs_refinement dans le contrôleur'
  },
  {
    path: 'app/javascript/controllers/test_eligibilite_controller.js',
    check: '/bruxelles/test-eligibility',
    description: 'URL corrigée dans showAffinageBruxelles'
  },
  {
    path: 'app/views/pages/bruxelles.html.erb',
    check: '<div id="eligibility_content">',
    description: 'Div normale au lieu de turbo_frame_tag'
  },
  {
    path: 'app/views/pages/partials_bruxelles/_resultat_eligible.html.erb',
    check: 'needs_refinement',
    description: 'Template avec logique needs_refinement'
  }
]

all_good = true

files_to_check.each do |file_check|
  if File.exist?(file_check[:path])
    content = File.read(file_check[:path])
    if content.include?(file_check[:check])
      puts "✅ #{file_check[:description]}"
    else
      puts "❌ #{file_check[:description]} - MANQUANT"
      all_good = false
    end
  else
    puts "❌ Fichier manquant: #{file_check[:path]}"
    all_good = false
  end
end

puts "\n" + "="*50
if all_good
  puts "🎉 Toutes les corrections sont en place !"
  puts "\nTest recommandé :"
  puts "1. Démarrer le serveur: bin/rails server"
  puts "2. Aller sur /bruxelles"
  puts "3. Tester le profil 'particulier'"
  puts "4. Vérifier que les résultats s'affichent"
  puts "5. Tester le bouton 'Calculer ma catégorie'"
else
  puts "⚠️  Des corrections sont nécessaires."
end
