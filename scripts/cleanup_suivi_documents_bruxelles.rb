#!/usr/bin/env ruby
# Script pour supprimer les documents Suivi obsolètes Bruxelles
# Usage: heroku run "DRY_RUN=false rails runner scripts/cleanup_suivi_documents_bruxelles.rb"

puts "🧹 Nettoyage des documents Suivi obsolètes - Bruxelles"
puts "=" * 60

# Mode simulation par défaut - changer à false pour exécution réelle
DRY_RUN = ENV['DRY_RUN'] != 'false'

if DRY_RUN
  puts "🚨 MODE SIMULATION - Aucune modification ne sera effectuée"
  puts "   Pour exécuter réellement: DRY_RUN=false"
else
  puts "⚡ MODE EXÉCUTION - Les modifications seront appliquées"
end

puts

# Documents Suivi à supprimer (ingénieur stabilité et expert façade)
SUIVI_DOCUMENTS_TO_DELETE = [137, 138, 139, 140]
# 137: Attestation entrepreneur - Suivi ingénieur stabilité
# 138: Guide de remplissage - Suivi ingénieur stabilité  
# 139: Attestation entrepreneur - Suivi expert façade
# 140: Guide de remplissage - Suivi expert façade

puts "📊 Documents Suivi à supprimer:"
puts "=" * 40

deleted_count = 0

SUIVI_DOCUMENTS_TO_DELETE.each do |doc_id|
  document = PrimeDocumentTemplate.find_by(id: doc_id)
  
  if document
    puts "🗑️  Document ID #{doc_id}: #{document.title}"
    puts "   Prime: #{document.prime.titre}"
    
    if DRY_RUN
      puts "   🔍 [SIMULATION] Suppression simulée"
    else
      begin
        document.destroy!
        puts "   ✅ Suppression réussie"
        deleted_count += 1
      rescue => e
        puts "   ❌ Erreur: #{e.message}"
      end
    end
    puts
  else
    puts "⚠️  Document ID #{doc_id} déjà supprimé ou non trouvé"
    puts
  end
end

puts "📊 RÉSULTATS:"
puts "=" * 40

if DRY_RUN
  puts "MODE SIMULATION - Aucune modification appliquée"
  puts "Documents qui seraient supprimés: #{SUIVI_DOCUMENTS_TO_DELETE.join(', ')}"
else
  puts "MODIFICATIONS APPLIQUÉES:"
  puts "- Documents Suivi supprimés: #{deleted_count}"
end

puts
puts "📊 VÉRIFICATION:"
puts "=" * 40

unless DRY_RUN
  puts "Vérification que les documents Suivi sont supprimés..."
  SUIVI_DOCUMENTS_TO_DELETE.each do |doc_id|
    doc = PrimeDocumentTemplate.find_by(id: doc_id)
    if doc.nil?
      puts "✅ ID #{doc_id}: Correctement supprimé"
    else
      puts "⚠️  ID #{doc_id}: Encore présent - #{doc.title}"
    end
  end
  
  puts
  puts "Documents Suivi restants après nettoyage:"
  remaining_suivi = PrimeDocumentTemplate.joins(:prime)
                      .where(primes: { region: 'bruxelles' })
                      .where('title LIKE ?', '%Suivi%')
  
  if remaining_suivi.any?
    remaining_suivi.each do |doc|
      puts "⚠️  ID #{doc.id}: #{doc.title} (Prime: #{doc.prime.titre})"
    end
  else
    puts "✅ Aucun document Suivi restant"
  end
end

puts
puts "🏁 Nettoyage terminé"