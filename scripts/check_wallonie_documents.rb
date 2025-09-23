#!/usr/bin/env ruby
# Script pour analyser les documents pour la région Wallonie
# Usage: rails runner scripts/check_wallonie_documents.rb

puts "🔍 Analyse des documents pour la région Wallonie"
puts "=" * 80

# Récupérer tous les documents pour la Wallonie
attestations = PrimeDocumentTemplate.joins(:prime)
                                   .where(primes: { region: 'wallonie' }, type_document: 'attestation_entrepreneur')
                                   .includes(:prime)
                                   .order(:id)

formulaires = PrimeDocumentTemplate.joins(:prime)
                                  .where(primes: { region: 'wallonie' }, type_document: 'formulaire_demande')
                                  .includes(:prime)
                                  .order(:id)

puts "📊 SITUATION ACTUELLE:"
puts "- Attestations d'entrepreneur: #{attestations.count}"
puts "- Formulaires de demande: #{formulaires.count}"
puts

if attestations.any?
  puts "🏆 ATTESTATIONS D'ENTREPRENEUR WALLONIE (#{attestations.count}):"
  puts "=" * 60
  attestations.each_with_index do |template, index|
    puts "#{index + 1}. ID: #{template.id}"
    puts "   Titre: #{template.title}"
    puts "   Prime: #{template.prime.titre} (ID: #{template.prime.id})"
    puts "   Slug prime: #{template.prime.slug}"
    puts "   Obligatoire: #{template.is_required ? 'Oui' : 'Non'}"
    puts "   Position: #{template.order_position}"
    puts "   Créé le: #{template.created_at.strftime('%d/%m/%Y à %H:%M')}"
    puts "   Fichier disponible: #{template.file_available? ? 'Oui' : 'Non'}"
    if template.file_url.present?
      puts "   URL: #{template.file_url}"
    end
    puts
  end
else
  puts "❌ Aucune attestation d'entrepreneur trouvée pour la Wallonie"
end

if formulaires.any?
  puts "📋 FORMULAIRES DE DEMANDE WALLONIE (#{formulaires.count}):"
  puts "=" * 60
  formulaires.each_with_index do |template, index|
    puts "#{index + 1}. ID: #{template.id}"
    puts "   Titre: #{template.title}"
    puts "   Prime: #{template.prime.titre} (ID: #{template.prime.id})"
    puts "   Slug prime: #{template.prime.slug}"
    puts "   Obligatoire: #{template.is_required ? 'Oui' : 'Non'}"
    puts "   Position: #{template.order_position}"
    puts "   Créé le: #{template.created_at.strftime('%d/%m/%Y à %H:%M')}"
    puts "   Fichier disponible: #{template.file_available? ? 'Oui' : 'Non'}"
    if template.file_url.present?
      puts "   URL: #{template.file_url}"
    end
    puts
  end
else
  puts "❌ Aucun formulaire de demande trouvé pour la Wallonie"
end

# Analyser les primes Wallonie
all_wallonie_primes = Prime.where(region: 'wallonie')
puts "🎯 PRIMES WALLONIE DISPONIBLES (#{all_wallonie_primes.count}):"
puts "=" * 60

primes_with_attestation = attestations.map(&:prime).uniq
primes_without_attestation = all_wallonie_primes - primes_with_attestation

all_wallonie_primes.each_with_index do |prime, index|
  has_attestation = primes_with_attestation.include?(prime)
  puts "#{index + 1}. #{prime.titre} (ID: #{prime.id})"
  puts "   Slug: #{prime.slug}"
  puts "   Attestation: #{has_attestation ? '✅ Oui' : '❌ Non'}"
  puts
end

if primes_without_attestation.any?
  puts "⚠️  PRIMES WALLONIE SANS ATTESTATION D'ENTREPRENEUR:"
  primes_without_attestation.each do |prime|
    puts "  - #{prime.titre} (ID: #{prime.id}, Slug: #{prime.slug})"
  end
  puts
end

# Statistiques finales
puts "📈 RÉSUMÉ:"
puts "=" * 40
puts "- Total primes Wallonie: #{all_wallonie_primes.count}"
puts "- Attestations d'entrepreneur: #{attestations.count}"
puts "- Formulaires de demande: #{formulaires.count}"
puts "- Primes avec attestation: #{primes_with_attestation.count}"
puts "- Primes sans attestation: #{primes_without_attestation.count}"
puts

puts "🎯 OBJECTIF:"
puts "- Réduire les attestations de #{attestations.count} à 7"
puts "- Ajouter 2 formulaires de demande (actuellement #{formulaires.count})"
puts "- Total documents finaux: 9 (7 attestations + 2 formulaires)"

puts
puts "🔗 Vérification de la configuration Cloudinary..."

# Vérifier la configuration Cloudinary
if defined?(Cloudinary)
  puts "✅ Cloudinary configuré"
  puts "   Cloud name: #{Cloudinary.config.cloud_name}" if Cloudinary.config.cloud_name
else
  puts "❌ Cloudinary non configuré"
end

puts
puts "🏁 Analyse terminée"
