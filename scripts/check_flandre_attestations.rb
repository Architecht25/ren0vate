#!/usr/bin/env ruby
# Script pour analyser les documents attestation_entrepreneur en Flandre
# Usage en production: heroku run rails runner scripts/check_flandre_attestations.rb

puts "🔍 Analyse des documents attestation_entrepreneur pour la région Flandre"
puts "=" * 80

# Récupérer tous les documents attestation_entrepreneur pour la Flandre
templates = PrimeDocumentTemplate.joins(:prime)
                                .where(primes: { region: 'flandre' }, type_document: 'attestation_entrepreneur')
                                .includes(:prime)
                                .order(:id)

puts "📊 Nombre total de documents trouvés: #{templates.count}"
puts

# Afficher tous les documents avec détails
templates.each_with_index do |template, index|
  puts "#{index + 1}. ID: #{template.id}"
  puts "   Titre: #{template.title}"
  puts "   Prime: #{template.prime.titre} (ID: #{template.prime.id})"
  puts "   Slug prime: #{template.prime.slug}"
  puts "   Région: #{template.prime.region}"
  puts "   Obligatoire: #{template.is_required ? 'Oui' : 'Non'}"
  puts "   Position: #{template.order_position}"
  puts "   Créé le: #{template.created_at.strftime('%d/%m/%Y à %H:%M')}"
  puts "   Fichier disponible: #{template.file_available? ? 'Oui' : 'Non'}"
  puts
end

# Grouper par prime pour analyser les doublons
primes_with_docs = templates.group_by(&:prime)

puts "🔍 Analyse par prime:"
puts "=" * 40

primes_with_docs.each do |prime, docs|
  puts "Prime: #{prime.titre}"
  puts "  - Nombre de documents: #{docs.count}"
  if docs.count > 1
    puts "  ⚠️  ATTENTION: Plusieurs documents attestation_entrepreneur pour cette prime!"
    docs.each do |doc|
      puts "     * ID #{doc.id}: #{doc.title}"
    end
  end
  puts
end

# Statistiques finales
puts "📈 Statistiques:"
puts "- Total documents: #{templates.count}"
puts "- Primes concernées: #{primes_with_docs.keys.count}"
puts "- Documents obligatoires: #{templates.where(is_required: true).count}"
puts "- Documents optionnels: #{templates.where(is_required: false).count}"

# Rechercher les primes de Flandre qui n'ont PAS de document attestation_entrepreneur
all_flandre_primes = Prime.where(region: 'flandre')
primes_with_attestation = templates.map(&:prime).uniq
primes_without_attestation = all_flandre_primes - primes_with_attestation

if primes_without_attestation.any?
  puts
  puts "⚠️  Primes Flandre SANS document attestation_entrepreneur:"
  primes_without_attestation.each do |prime|
    puts "  - #{prime.titre} (ID: #{prime.id}, Slug: #{prime.slug})"
  end
else
  puts
  puts "✅ Toutes les primes Flandre ont un document attestation_entrepreneur"
end

puts
puts "🎯 Recommandations pour avoir exactement 8 documents:"
if templates.count > 8
  excess_count = templates.count - 8
  puts "❌ Il y a #{excess_count} document(s) en trop à supprimer"

  # Suggérer les documents à supprimer (les plus récents ou doublons)
  duplicate_docs = []
  primes_with_docs.each do |prime, docs|
    if docs.count > 1
      # Garder le plus ancien, marquer les autres comme à supprimer
      oldest = docs.min_by(&:created_at)
      others = docs - [oldest]
      duplicate_docs.concat(others)
    end
  end

  if duplicate_docs.any?
    puts "📝 Documents suggérés pour suppression (doublons):"
    duplicate_docs.each do |doc|
      puts "  - ID #{doc.id}: #{doc.title} (Prime: #{doc.prime.titre})"
    end
  end

elsif templates.count < 8
  missing_count = 8 - templates.count
  puts "📈 Il manque #{missing_count} document(s) pour atteindre 8"
else
  puts "✅ Le nombre de documents est correct (8)"
end
