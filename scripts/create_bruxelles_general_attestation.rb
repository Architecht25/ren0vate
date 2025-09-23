#!/usr/bin/env ruby
# Script pour créer l'attestation générale unique pour Bruxelles
# Usage: rails runner scripts/create_bruxelles_general_attestation.rb

puts "🔧 Création de l'attestation générale unique pour Bruxelles"
puts "=" * 70

# Mode simulation par défaut - changer à false pour exécution réelle
DRY_RUN = ENV['DRY_RUN'] != 'false'

if DRY_RUN
  puts "🚨 MODE SIMULATION - Aucune modification ne sera effectuée"
  puts "   Pour exécuter réellement: DRY_RUN=false rails runner scripts/create_bruxelles_general_attestation.rb"
else
  puts "⚡ MODE EXÉCUTION - Les modifications seront appliquées"
end

puts

# Configuration de l'attestation générale
GENERAL_ATTESTATION_CONFIG = {
  cloudinary_id: '_AttestationEntrepreneur_fr_yz8wkf',
  title: 'Attestation entrepreneur générale - Bruxelles',
  description: 'Document d\'attestation générale obligatoire pour toutes les demandes de primes à Bruxelles. Ce document doit accompagner toute demande de prime et est indépendant des attestations spécifiques à chaque prime.',
  type_document: 'attestation_generale',
  is_required: true,
  order_position: 1
}

# Générer l'URL Cloudinary complète
def generate_cloudinary_url(cloudinary_id)
  "https://res.cloudinary.com/dtdelexhd/image/upload/#{cloudinary_id}.pdf"
end

puts "📊 ÉTAPE 1: Vérification de l'existence de l'attestation générale"
puts "=" * 60

# Nous devons créer l'attestation générale sans l'associer à une prime spécifique
# Pour cela, nous allons trouver une prime de référence Bruxelles ou créer un système différent

# Option 1: Chercher une prime de référence (première prime A1 par exemple)
reference_prime = Prime.where(region: 'bruxelles', slug: 'bruxelles_audit_energetique_maison').first

if reference_prime.nil?
  puts "❌ Aucune prime de référence trouvée pour Bruxelles"
  puts "   Recherche d'une prime Bruxelles quelconque..."
  reference_prime = Prime.where(region: 'bruxelles').first
end

if reference_prime.nil?
  puts "❌ Aucune prime Bruxelles trouvée dans la base de données"
  exit 1
end

puts "✅ Prime de référence trouvée: #{reference_prime.titre} (ID: #{reference_prime.id})"

# Vérifier si l'attestation générale existe déjà
existing_general = PrimeDocumentTemplate.where(
  prime: reference_prime,
  type_document: 'attestation_generale'
).first

puts "📊 ÉTAPE 2: Création ou mise à jour de l'attestation générale"
puts "=" * 60

cloudinary_url = generate_cloudinary_url(GENERAL_ATTESTATION_CONFIG[:cloudinary_id])

if existing_general
  puts "⚠️  Une attestation générale existe déjà (ID: #{existing_general.id})"
  puts "   Titre actuel: #{existing_general.title}"
  puts "   URL actuelle: #{existing_general.file_url}"

  if DRY_RUN
    puts "📝 [SIMULATION] Mise à jour de l'attestation existante"
    puts "     Nouveau titre: #{GENERAL_ATTESTATION_CONFIG[:title]}"
    puts "     Nouvelle URL: #{cloudinary_url}"
  else
    begin
      existing_general.update!(
        title: GENERAL_ATTESTATION_CONFIG[:title],
        description: GENERAL_ATTESTATION_CONFIG[:description],
        file_url: cloudinary_url,
        is_required: GENERAL_ATTESTATION_CONFIG[:is_required],
        order_position: GENERAL_ATTESTATION_CONFIG[:order_position]
      )
      puts "✅ Attestation générale mise à jour (ID: #{existing_general.id})"
      puts "   Nouveau titre: #{existing_general.title}"
      puts "   Nouvelle URL: #{existing_general.file_url}"
    rescue => e
      puts "❌ Erreur lors de la mise à jour: #{e.message}"
      exit 1
    end
  end
else
  puts "➕ Création d'une nouvelle attestation générale"

  if DRY_RUN
    puts "📝 [SIMULATION] Création attestation générale"
    puts "     Titre: #{GENERAL_ATTESTATION_CONFIG[:title]}"
    puts "     URL: #{cloudinary_url}"
    puts "     Prime de référence: #{reference_prime.titre}"
    puts "     Type: #{GENERAL_ATTESTATION_CONFIG[:type_document]}"
  else
    begin
      new_attestation = PrimeDocumentTemplate.create!(
        prime: reference_prime,
        type_document: GENERAL_ATTESTATION_CONFIG[:type_document],
        title: GENERAL_ATTESTATION_CONFIG[:title],
        description: GENERAL_ATTESTATION_CONFIG[:description],
        file_url: cloudinary_url,
        is_required: GENERAL_ATTESTATION_CONFIG[:is_required],
        order_position: GENERAL_ATTESTATION_CONFIG[:order_position]
      )

      puts "✅ Attestation générale créée (ID: #{new_attestation.id})"
      puts "   Titre: #{new_attestation.title}"
      puts "   URL: #{new_attestation.file_url}"
      puts "   Prime de référence: #{reference_prime.titre}"
    rescue => e
      puts "❌ Erreur lors de la création: #{e.message}"
      exit 1
    end
  end
end

puts
puts "📊 ÉTAPE 3: Vérification finale"
puts "=" * 60

unless DRY_RUN
  # Vérifier que l'attestation générale existe bien
  final_attestation = PrimeDocumentTemplate.where(
    type_document: 'attestation_generale'
  ).where(
    'title LIKE ?', '%Bruxelles%'
  ).first

  if final_attestation
    puts "✅ Attestation générale Bruxelles confirmée:"
    puts "   ID: #{final_attestation.id}"
    puts "   Titre: #{final_attestation.title}"
    puts "   URL: #{final_attestation.file_url}"
    puts "   Prime associée: #{final_attestation.prime.titre}"
    puts "   Type: #{final_attestation.type_document}"
    puts "   Obligatoire: #{final_attestation.is_required ? 'Oui' : 'Non'}"
  else
    puts "❌ Erreur: Attestation générale non trouvée après création"
  end
end

puts
puts "📋 RÉSUMÉ:"
puts "=" * 40

if DRY_RUN
  puts "MODE SIMULATION - Aucune modification appliquée"
  puts "L'attestation générale sera:"
  puts "- Titre: #{GENERAL_ATTESTATION_CONFIG[:title]}"
  puts "- URL Cloudinary: #{cloudinary_url}"
  puts "- Type: #{GENERAL_ATTESTATION_CONFIG[:type_document]}"
  puts "- Obligatoire: Oui"
  puts "- Prime de référence: #{reference_prime.titre}"
else
  puts "✅ Attestation générale Bruxelles configurée avec succès!"
  puts "   Cette attestation apparaîtra dans la liste des documents"
  puts "   et sera obligatoire pour toutes les demandes Bruxelles."
end

puts
puts "🏁 Configuration terminée"

if DRY_RUN
  puts
  puts "💡 Pour exécuter réellement:"
  puts "   DRY_RUN=false rails runner scripts/create_bruxelles_general_attestation.rb"
end
