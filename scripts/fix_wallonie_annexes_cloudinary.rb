#!/usr/bin/env ruby
# Script pour corriger les URLs des annexes techniques de Wallonie vers Cloudinary
# Usage: heroku run "DRY_RUN=false rails runner scripts/fix_wallonie_annexes_cloudinary.rb"

puts "🔧 Correction des URLs des annexes techniques Wallonie vers Cloudinary"
puts "=" * 80

# Mode simulation par défaut - changer à false pour exécution réelle
DRY_RUN = ENV['DRY_RUN'] != 'false'

if DRY_RUN
  puts "🚨 MODE SIMULATION - Aucune modification ne sera effectuée"
  puts "   Pour exécuter réellement: DRY_RUN=false"
else
  puts "⚡ MODE EXÉCUTION PRODUCTION - Les modifications seront appliquées"
end

puts

# Mapping des annexes de Wallonie vers leurs IDs Cloudinary
WALLONIE_ANNEXES_MAPPING = {
  # Annexe 1 - Toiture
  'wallonie_toiture_isolation_thermique' => '13-03-2025_pdf-annexe-1-toiture-primes-habitation_rochbb',
  'wallonie_toiture_isolation_biosource' => '13-03-2025_pdf-annexe-1-toiture-primes-habitation_rochbb',
  
  # Annexe 2 - Murs  
  'wallonie_isolation_murs' => '13-03-2025_pdf-annexe-2-murs-primes-habitation_klxegb',
  'wallonie_isolation_murs_biosource' => '13-03-2025_pdf-annexe-2-murs-primes-habitation_klxegb',
  
  # Annexe 5 - Pour sols (électricité/technique est plus approprié que menuiseries)
  'wallonie_isolation_sols' => '13-03-2025_pdf-annexe-5-gaz-electricite-radon-merule-primes-habitation_imn92l',
  'wallonie_isolation_sols_biosource' => '13-03-2025_pdf-annexe-5-gaz-electricite-radon-merule-primes-habitation_imn92l',
  
  # Annexe 6 - Chauffage/Installation pour finition planchers
  'wallonie_isolation_finition_planchers' => '13-03-2025_pdf-annexe-6-installation-de-chauffage-et-ecs-primes-habitation_ylbxzh'
}

def generate_cloudinary_url(cloudinary_id)
  "https://res.cloudinary.com/dtdelexhd/image/upload/#{cloudinary_id}.pdf"
end

puts "📊 Correction des annexes techniques Wallonie"
puts "=" * 60

# Récupérer toutes les annexes techniques de Wallonie
annexes = PrimeDocumentTemplate.joins(:prime)
                               .where(primes: { region: 'wallonie' }, 
                                      type_document: 'annexe_technique')

puts "🔍 Trouvé #{annexes.count} annexes techniques pour la Wallonie"
puts

updated_count = 0
not_found_count = 0

annexes.each do |annexe|
  prime_slug = annexe.prime.slug
  current_url = annexe.file_url
  
  puts "📝 Traitement de: #{annexe.title}"
  puts "   Prime slug: #{prime_slug}"
  puts "   URL actuelle: #{current_url}"
  
  if WALLONIE_ANNEXES_MAPPING.key?(prime_slug)
    cloudinary_id = WALLONIE_ANNEXES_MAPPING[prime_slug]
    new_url = generate_cloudinary_url(cloudinary_id)
    
    puts "   ✅ Mapping trouvé: #{cloudinary_id}"
    puts "   🔗 Nouvelle URL: #{new_url}"
    
    if !DRY_RUN
      begin
        annexe.update!(file_url: new_url)
        puts "   💾 Mis à jour avec succès!"
        updated_count += 1
      rescue => e
        puts "   ❌ Erreur lors de la mise à jour: #{e.message}"
      end
    else
      puts "   🔄 Serait mis à jour (mode simulation)"
      updated_count += 1
    end
  else
    puts "   ⚠️  Aucun mapping trouvé pour le slug: #{prime_slug}"
    not_found_count += 1
  end
  
  puts
end

puts "=" * 60
puts "📊 RÉSUMÉ"
puts "Documents traités: #{annexes.count}"
puts "Documents mis à jour: #{updated_count}"
puts "Documents sans mapping: #{not_found_count}"

if DRY_RUN
  puts
  puts "🚨 MODE SIMULATION - Aucune modification effectuée"
  puts "   Pour appliquer les changements: DRY_RUN=false rails runner scripts/fix_wallonie_annexes_cloudinary.rb"
else
  puts
  puts "✅ Script terminé - Modifications appliquées en production"
end

puts "=" * 80