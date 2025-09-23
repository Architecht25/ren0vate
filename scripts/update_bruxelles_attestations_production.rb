#!/usr/bin/env ruby
# Script pour mettre à jour les documents Bruxelles en PRODUCTION
# Usage: heroku run "DRY_RUN=false rails runner scripts/update_bruxelles_attestations_production.rb"

puts "🔧 Mise à jour des documents d'attestation entrepreneur Bruxelles (PRODUCTION)"
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

# Configuration des documents à mettre à jour avec nouveaux Cloudinary IDs
DOCUMENTS_TO_UPDATE = {
  127 => {  # A1 - Attestation maison
    cloudinary_id: 'A1_-_Cahier_minimal_des_charges_-_Audit_énegétique_kg5pyz',
    title: 'A1 - Cahier minimal des charges - Audit énergétique'
  },
  129 => {  # A1 - Attestation bâtiment complet
    cloudinary_id: 'A1_-_Cahier_minimal_des_charges_-_Audit_énegétique_kg5pyz',
    title: 'A1 - Cahier minimal des charges - Audit énergétique'
  },
  133 => {  # A3 - Étude TOTEM
    cloudinary_id: 'A3_-_Cahier_minimal_des_charges_-_Etude_matériaux_de_construction_totem_ftgzpk',
    title: 'A3 - Cahier minimal des charges - Étude matériaux de construction TOTEM'
  }
}

# IDs des documents à supprimer (A2, A4, A5)
DOCUMENTS_TO_DELETE = [131, 135, 141]

def generate_cloudinary_url(cloudinary_id)
  "https://res.cloudinary.com/dtdelexhd/image/upload/#{cloudinary_id}.pdf"
end

puts "📊 ÉTAPE 1: Mise à jour des documents avec nouveaux Cloudinary IDs"
puts "=" * 60

updated_count = 0

DOCUMENTS_TO_UPDATE.each do |doc_id, config|
  document = PrimeDocumentTemplate.find_by(id: doc_id)

  if document
    old_url = document.file_url
    new_url = generate_cloudinary_url(config[:cloudinary_id])

    puts "📝 Document ID #{doc_id}: #{document.title}"
    puts "   Ancien titre: #{document.title}"
    puts "   Nouveau titre: #{config[:title]}"
    puts "   Ancienne URL: #{old_url}"
    puts "   Nouvelle URL: #{new_url}"

    if DRY_RUN
      puts "   🔍 [SIMULATION] Mise à jour simulée"
    else
      begin
        document.update!(
          title: config[:title],
          file_url: new_url
        )
        puts "   ✅ Mise à jour réussie"
        updated_count += 1
      rescue => e
        puts "   ❌ Erreur: #{e.message}"
      end
    end
    puts
  else
    puts "❌ Document ID #{doc_id} non trouvé"
    puts
  end
end

puts "📊 ÉTAPE 2: Suppression des documents obsolètes (A2, A4, A5)"
puts "=" * 60

deleted_count = 0

DOCUMENTS_TO_DELETE.each do |doc_id|
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
  puts "Documents qui seraient mis à jour: #{DOCUMENTS_TO_UPDATE.keys.join(', ')}"
  puts "Documents qui seraient supprimés: #{DOCUMENTS_TO_DELETE.join(', ')}"
else
  puts "MODIFICATIONS APPLIQUÉES:"
  puts "- Documents mis à jour: #{updated_count}"
  puts "- Documents supprimés: #{deleted_count}"
end

puts "📊 ÉTAPE 3: Vérification post-modification"
puts "=" * 60

unless DRY_RUN
  puts "Vérification des documents A1 et A3 mis à jour..."
  [127, 129, 133].each do |doc_id|
    doc = PrimeDocumentTemplate.find_by(id: doc_id)
    if doc
      puts "✅ ID #{doc_id}: #{doc.title}"
      puts "   URL: #{doc.file_url}"
    end
  end

  puts
  puts "Vérification que A2, A4, A5 sont supprimés..."
  [131, 135, 141].each do |doc_id|
    doc = PrimeDocumentTemplate.find_by(id: doc_id)
    if doc.nil?
      puts "✅ ID #{doc_id}: Correctement supprimé"
    else
      puts "⚠️  ID #{doc_id}: Encore présent - #{doc.title}"
    end
  end
end

puts
puts "🏁 Mise à jour terminée"
