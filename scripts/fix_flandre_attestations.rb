#!/usr/bin/env ruby
# Script pour corriger les documents attestation_entrepreneur en Flandre
# Usage en production: heroku run rails runner scripts/fix_flandre_attestations.rb

puts "🔧 Correction des documents attestation_entrepreneur pour la région Flandre"
puts "=" * 80

# Mode simulation par défaut - changer à false pour exécution réelle
DRY_RUN = ENV['DRY_RUN'] != 'false'

if DRY_RUN
  puts "🚨 MODE SIMULATION - Aucune modification ne sera effectuée"
  puts "   Pour exécuter réellement: DRY_RUN=false heroku run rails runner scripts/fix_flandre_attestations.rb"
else
  puts "⚡ MODE EXÉCUTION - Les modifications seront appliquées"
end

puts

# Récupérer tous les documents attestation_entrepreneur pour la Flandre
templates = PrimeDocumentTemplate.joins(:prime)
                                .where(primes: { region: 'flandre' }, type_document: 'attestation_entrepreneur')
                                .includes(:prime)
                                .order(:created_at)

puts "📊 Documents actuels: #{templates.count}"

# Identifier les documents à conserver (8 documents attendus)
# On garde les 8 documents les plus pertinents selon les primes du développement

# IDs des primes qui ont des documents en développement (basé sur votre listing)
expected_prime_titles = [
  "Isolation du sol / plancher bas et sol cave",
  "Isolation des murs extérieurs (cat. 3-4)",
  "Remplacement des châssis et portes extérieures",
  "Pompe à chaleur",
  "Isolation des murs extérieurs (cat. 1-2)",
  "Chauffe-eau thermodynamique",
  "Isolation de la toiture",
  "Prime amiante"
]

# Trouver les documents correspondants
docs_to_keep = []
docs_to_remove = []

# Grouper par prime
primes_with_docs = templates.group_by(&:prime)

primes_with_docs.each do |prime, docs|
  if expected_prime_titles.any? { |title| prime.titre.include?(title.split(' ').first) }
    # Prime attendue - garder le document le plus ancien
    if docs.count == 1
      docs_to_keep << docs.first
    else
      docs_to_keep << docs.min_by(&:created_at)
      docs_to_remove.concat(docs - [docs.min_by(&:created_at)])
    end
  else
    # Prime non attendue - tous les documents à supprimer
    docs_to_remove.concat(docs)
  end
end

# Si on a encore trop de documents à garder, ne garder que les 8 premiers
if docs_to_keep.count > 8
  extra_docs = docs_to_keep[8..-1]
  docs_to_keep = docs_to_keep[0...8]
  docs_to_remove.concat(extra_docs)
end

puts "📝 Plan d'action:"
puts "  - Documents à conserver: #{docs_to_keep.count}"
puts "  - Documents à supprimer: #{docs_to_remove.count}"
puts

if docs_to_keep.any?
  puts "✅ Documents à CONSERVER:"
  docs_to_keep.each_with_index do |doc, index|
    puts "  #{index + 1}. ID #{doc.id}: #{doc.title}"
    puts "     Prime: #{doc.prime.titre}"
  end
  puts
end

if docs_to_remove.any?
  puts "❌ Documents à SUPPRIMER:"
  docs_to_remove.each_with_index do |doc, index|
    puts "  #{index + 1}. ID #{doc.id}: #{doc.title}"
    puts "     Prime: #{doc.prime.titre}"
    puts "     Créé le: #{doc.created_at.strftime('%d/%m/%Y à %H:%M')}"
  end
  puts
end

# Exécution des suppressions
if docs_to_remove.any?
  if DRY_RUN
    puts "🚨 MODE SIMULATION - Ces #{docs_to_remove.count} documents seraient supprimés"
  else
    puts "🗑️  Suppression de #{docs_to_remove.count} documents..."

    deleted_count = 0
    failed_count = 0

    docs_to_remove.each do |doc|
      begin
        doc.destroy!
        deleted_count += 1
        puts "  ✅ Supprimé: ID #{doc.id} - #{doc.title}"
      rescue => e
        failed_count += 1
        puts "  ❌ Erreur ID #{doc.id}: #{e.message}"
      end
    end

    puts
    puts "📊 Résultats:"
    puts "  - Documents supprimés: #{deleted_count}"
    puts "  - Échecs: #{failed_count}"

    # Vérification finale
    remaining_templates = PrimeDocumentTemplate.joins(:prime)
                                             .where(primes: { region: 'flandre' }, type_document: 'attestation_entrepreneur')

    puts "  - Documents restants: #{remaining_templates.count}"

    if remaining_templates.count == 8
      puts "🎉 SUCCÈS! Il y a maintenant exactement 8 documents comme en développement"
    else
      puts "⚠️  ATTENTION: Il reste #{remaining_templates.count} documents (attendu: 8)"
    end
  end
else
  puts "✅ Aucun document à supprimer - le nombre est déjà correct"
end

puts
puts "🏁 Script terminé"
