#!/usr/bin/env ruby
# Script pour mettre à jour la Phase Réception en production
# Usage: RAILS_ENV=production rails runner scripts/update_phase_reception_production.rb

puts "🚀 Mise à jour de la Phase Réception pour les fiches techniques..."
puts "Environment: #{Rails.env}"

begin
  # Vérifier que nous sommes en production
  if Rails.env.production?
    puts "⚠️  ATTENTION: Exécution en PRODUCTION"
    puts "   Appuyez sur Entrée pour continuer ou Ctrl+C pour annuler..."
    # En production, on peut retirer cette ligne ou la garder pour la sécurité
    # STDIN.gets
  end

  # Trouver la Phase Réception
  phase_reception = DocumentPhase.find_by(name: 'Phase Réception')

  if phase_reception.nil?
    puts "❌ Phase Réception non trouvée!"
    exit 1
  end

  puts "📋 Phase trouvée:"
  puts "   ID: #{phase_reception.id}"
  puts "   Nom: #{phase_reception.name}"
  puts "   Documents optionnels actuels: #{phase_reception.optional_document_types.join(', ')}"

  # Vérifier si la modification est nécessaire
  if phase_reception.optional_document_types.include?('fiche_technique')
    puts "✅ La phase contient déjà 'fiche_technique'"
  else
    puts "🔄 Mise à jour nécessaire..."

    # Sauvegarder l'état actuel
    old_types = phase_reception.optional_document_types.dup

    # Effectuer la modification
    new_types = old_types.dup
    new_types.delete('photo') if new_types.include?('photo')
    new_types << 'fiche_technique' unless new_types.include?('fiche_technique')

    # Mettre à jour
    phase_reception.update!(optional_document_types: new_types)

    puts "✅ Mise à jour effectuée!"
    puts "   Avant: #{old_types.join(', ')}"
    puts "   Après: #{phase_reception.reload.optional_document_types.join(', ')}"
  end

  # Vérifications finales
  puts "\n🔍 Vérifications:"

  # Vérifier que l'enum fiche_technique existe
  if Document.type_documents.key?('fiche_technique')
    puts "✅ Énumération 'fiche_technique' disponible dans Document"
  else
    puts "❌ Énumération 'fiche_technique' manquante dans Document"
  end

  # Vérifier la traduction
  begin
    translation = I18n.t('documents.types.fiche_technique')
    puts "✅ Traduction disponible: '#{translation}'"
  rescue I18n::MissingTranslationData
    puts "❌ Traduction manquante pour 'documents.types.fiche_technique'"
  end

  puts "\n🎉 Script terminé avec succès!"

rescue => e
  puts "❌ Erreur lors de l'exécution:"
  puts "   #{e.class}: #{e.message}"
  puts "   #{e.backtrace.first}"
  exit 1
end
