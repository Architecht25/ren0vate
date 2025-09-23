#!/usr/bin/env ruby
# Script pour mettre à jour les documents d'attestation entrepreneur Bruxelles
# Usage: rails runner scripts/update_bruxelles_attestations.rb

puts "🔧 Mise à jour des documents d'attestation entrepreneur Bruxelles"
puts "=" * 80

# Mode simulation par défaut - changer à false pour exécution réelle
DRY_RUN = ENV['DRY_RUN'] != 'false'

if DRY_RUN
  puts "🚨 MODE SIMULATION - Aucune modification ne sera effectuée"
  puts "   Pour exécuter réellement: DRY_RUN=false rails runner scripts/update_bruxelles_attestations.rb"
else
  puts "⚡ MODE EXÉCUTION - Les modifications seront appliquées"
end

puts

# Configuration des documents à mettre à jour avec Cloudinary
CLOUDINARY_UPDATES = {
  'A1_audit_maison' => {
    document_id: 376,
    cloudinary_id: 'A1_-_Cahier_minimal_des_charges_-_Audit_énegétique_kg5pyz',
    title: 'A1 - Cahier minimal des charges - Audit énergétique',
    description: 'Cahier minimal des charges pour l\'audit énergétique (maison unifamiliale) - Bruxelles',
    slug_prime: 'bruxelles_audit_energetique_maison'
  },
  'A1_audit_batiment' => {
    document_id: 378,
    cloudinary_id: 'A1_-_Cahier_minimal_des_charges_-_Audit_énegétique_kg5pyz',
    title: 'A1 - Cahier minimal des charges - Audit énergétique',
    description: 'Cahier minimal des charges pour l\'audit énergétique (bâtiment complet) - Bruxelles',
    slug_prime: 'bruxelles_audit_energetique_batiment'
  },
  'A3_etude_totem' => {
    document_id: 382,
    cloudinary_id: 'A3_-_Cahier_minimal_des_charges_-_Etude_matériaux_de_construction_totem_ftgzpk',
    title: 'A3 - Cahier minimal des charges - Étude matériaux de construction (TOTEM)',
    description: 'Cahier minimal des charges pour l\'étude matériaux de construction TOTEM - Bruxelles',
    slug_prime: 'bruxelles_etude_totem'
  }
}

# Documents à supprimer (n'existent plus)
DOCUMENTS_TO_DELETE = [
  {
    document_id: 380,
    title: 'A2 - Étude acoustique',
    slug_prime: 'bruxelles_etude_acoustique'
  },
  {
    document_id: 384,
    title: 'A4 - Suivi architecte',
    slug_prime: 'bruxelles_suivi_architecte'
  },
  {
    document_id: 386,
    title: 'A4 - Suivi ingénieur stabilité',
    slug_prime: 'bruxelles_suivi_ingenieur_stabilite'
  },
  {
    document_id: 388,
    title: 'A4 - Suivi expert façade',
    slug_prime: 'bruxelles_suivi_expert_facade'
  },
  {
    document_id: 390,
    title: 'A5 - Certificat PEB',
    slug_prime: 'bruxelles_certificat_peb'
  }
]

# Générer l'URL Cloudinary complète
def generate_cloudinary_url(cloudinary_id)
  "https://res.cloudinary.com/dtdelexhd/image/upload/#{cloudinary_id}.pdf"
end

puts "📊 ÉTAPE 1: Mise à jour des documents avec Cloudinary"
puts "=" * 60

updated_count = 0

CLOUDINARY_UPDATES.each do |key, config|
  begin
    document = PrimeDocumentTemplate.find(config[:document_id])
    cloudinary_url = generate_cloudinary_url(config[:cloudinary_id])

    if DRY_RUN
      puts "📝 [SIMULATION] Mise à jour: #{document.title}"
      puts "     Nouveau titre: #{config[:title]}"
      puts "     Nouvelle URL: #{cloudinary_url}"
      puts "     Description: #{config[:description]}"
    else
      document.update!(
        title: config[:title],
        description: config[:description],
        file_url: cloudinary_url
      )
      updated_count += 1
      puts "✅ Mis à jour: #{config[:title]}"
      puts "   URL: #{cloudinary_url}"
    end

  rescue ActiveRecord::RecordNotFound
    puts "❌ Document ID #{config[:document_id]} non trouvé"
  rescue => e
    puts "❌ Erreur mise à jour #{config[:title]}: #{e.message}"
  end

  puts
end

puts "📊 ÉTAPE 2: Suppression des documents obsolètes"
puts "=" * 60

deleted_count = 0

DOCUMENTS_TO_DELETE.each do |config|
  begin
    document = PrimeDocumentTemplate.find(config[:document_id])

    if DRY_RUN
      puts "🗑️  [SIMULATION] Suppression: #{document.title}"
      puts "     ID: #{config[:document_id]}"
      puts "     Prime: #{config[:slug_prime]}"
    else
      document.destroy!
      deleted_count += 1
      puts "🗑️  Supprimé: #{config[:title]}"
      puts "   ID: #{config[:document_id]}"
    end

  rescue ActiveRecord::RecordNotFound
    puts "⚠️  Document ID #{config[:document_id]} déjà supprimé ou non trouvé"
  rescue => e
    puts "❌ Erreur suppression #{config[:title]}: #{e.message}"
  end

  puts
end

puts "📊 RÉSULTATS:"
puts "=" * 40

if DRY_RUN
  puts "MODE SIMULATION - Aucune modification appliquée"
  puts "Changements qui seraient effectués:"
  puts "- Mises à jour Cloudinary: #{CLOUDINARY_UPDATES.count} documents"
  puts "- Suppressions: #{DOCUMENTS_TO_DELETE.count} documents"
else
  puts "MODIFICATIONS APPLIQUÉES:"
  puts "- Documents mis à jour: #{updated_count}"
  puts "- Documents supprimés: #{deleted_count}"
end

puts
puts "📊 ÉTAPE 3: Vérification post-modification"
puts "=" * 60

unless DRY_RUN
  puts "Vérification des documents restants pour A1-A5..."

  remaining_a_docs = PrimeDocumentTemplate.joins(:prime)
                                         .where(primes: { region: 'bruxelles' }, type_document: 'attestation_entrepreneur')
                                         .where('prime_document_templates.title LIKE ?', '%A1%')
                                         .or(
                                           PrimeDocumentTemplate.joins(:prime)
                                                               .where(primes: { region: 'bruxelles' }, type_document: 'attestation_entrepreneur')
                                                               .where('prime_document_templates.title LIKE ?', '%A2%')
                                         )
                                         .or(
                                           PrimeDocumentTemplate.joins(:prime)
                                                               .where(primes: { region: 'bruxelles' }, type_document: 'attestation_entrepreneur')
                                                               .where('prime_document_templates.title LIKE ?', '%A3%')
                                         )
                                         .or(
                                           PrimeDocumentTemplate.joins(:prime)
                                                               .where(primes: { region: 'bruxelles' }, type_document: 'attestation_entrepreneur')
                                                               .where('prime_document_templates.title LIKE ?', '%A4%')
                                         )
                                         .or(
                                           PrimeDocumentTemplate.joins(:prime)
                                                               .where(primes: { region: 'bruxelles' }, type_document: 'attestation_entrepreneur')
                                                               .where('prime_document_templates.title LIKE ?', '%A5%')
                                         )

  if remaining_a_docs.any?
    puts "Documents A1-A5 restants:"
    remaining_a_docs.each do |doc|
      puts "✅ #{doc.title}"
      puts "   URL: #{doc.file_url}"
      puts
    end
  else
    puts "⚠️  Aucun document A1-A5 trouvé après modification"
  end
end

puts
puts "🏁 Mise à jour terminée"

if DRY_RUN
  puts
  puts "💡 Pour exécuter réellement:"
  puts "   DRY_RUN=false rails runner scripts/update_bruxelles_attestations.rb"
end
