#!/usr/bin/env ruby
# Script pour supprimer tous les guides de remplissage (type_document: 'guide_remplissage')
# Usage: rails runner scripts/delete_guides_remplissage.rb
# Usage en production: heroku run "DRY_RUN=false rails runner scripts/delete_guides_remplissage.rb"

puts "🗑️  Suppression des guides de remplissage"
puts "=" * 80

# Mode simulation par défaut - changer à false pour exécution réelle
DRY_RUN = ENV['DRY_RUN'] != 'false'

if DRY_RUN
  puts "🚨 MODE SIMULATION - Aucune suppression ne sera effectuée"
  puts "   Pour exécuter réellement: DRY_RUN=false"
else
  puts "⚡ MODE EXÉCUTION RÉELLE - Les guides seront supprimés"
  puts "⚠️  ATTENTION: Cette action est irréversible!"
end

puts

# Récupérer tous les guides de remplissage
guides = PrimeDocumentTemplate.where(type_document: 'guide_remplissage')

puts "🔍 Analyse des guides de remplissage"
puts "=" * 60
puts "Nombre total de guides trouvés: #{guides.count}"

if guides.count == 0
  puts "✅ Aucun guide de remplissage à supprimer"
  exit 0
end

puts

# Afficher un échantillon des guides à supprimer
puts "📋 Aperçu des guides à supprimer (premiers 10):"
guides.limit(10).each_with_index do |guide, index|
  prime_info = guide.prime ? "#{guide.prime.titre} (#{guide.prime.region})" : "Document général"
  puts "  #{index + 1}. ID: #{guide.id} - #{guide.title}"
  puts "     Prime: #{prime_info}"
  puts "     URL: #{guide.file_url}" if guide.file_url.present?
  puts "     Fichier attaché: #{guide.document_file.attached? ? 'Oui' : 'Non'}"
  puts
end

if guides.count > 10
  puts "  ... et #{guides.count - 10} autres guides"
  puts
end

# Répartition par région
puts "📊 Répartition par région:"
guides.joins(:prime).group('primes.region').count.each do |region, count|
  puts "  #{region&.capitalize || 'Non défini'}: #{count} guides"
end

guides_without_prime = guides.where(prime: nil).count
if guides_without_prime > 0
  puts "  Documents généraux (sans prime): #{guides_without_prime} guides"
end

puts

# Suppression effective
if !DRY_RUN
  puts "🗑️  SUPPRESSION EN COURS..."
  puts "=" * 40
  
  deleted_count = 0
  error_count = 0
  
  guides.find_each do |guide|
    begin
      # Supprimer d'abord le fichier attaché s'il existe
      if guide.document_file.attached?
        guide.document_file.purge
      end
      
      # Supprimer l'enregistrement
      guide.destroy!
      deleted_count += 1
      
      if deleted_count % 10 == 0
        puts "  ✅ #{deleted_count} guides supprimés..."
      end
      
    rescue => e
      puts "  ❌ Erreur lors de la suppression du guide ID #{guide.id}: #{e.message}"
      error_count += 1
    end
  end
  
  puts "=" * 40
  puts "📊 RÉSUMÉ DE LA SUPPRESSION"
  puts "Guides supprimés avec succès: #{deleted_count}"
  puts "Erreurs rencontrées: #{error_count}"
  puts "Total traité: #{deleted_count + error_count}"
  
  if error_count == 0
    puts "✅ Tous les guides de remplissage ont été supprimés avec succès!"
  else
    puts "⚠️  Quelques erreurs ont été rencontrées lors de la suppression"
  end
  
else
  puts "🔄 MODE SIMULATION - Actions qui seraient effectuées:"
  puts "  - Suppression de #{guides.count} guides de remplissage"
  puts "  - Suppression des fichiers attachés associés"
  puts
  puts "Pour exécuter réellement:"
  puts "  DRY_RUN=false rails runner scripts/delete_guides_remplissage.rb"
end

puts "=" * 80