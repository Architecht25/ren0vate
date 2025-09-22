#!/usr/bin/env ruby
# Script pour créer la Prime amiante manquante en production
# Usage: heroku run rails runner scripts/create_amiante_prime.rb

puts '🔧 Création de la Prime amiante en production'
puts '=' * 50

# Vérifier si elle existe déjà
existing_prime = Prime.find_by(slug: 'amiante', region: 'flandre')

if existing_prime
  puts '✅ Prime amiante existe déjà en production'
  puts "   ID: #{existing_prime.id}"
  puts "   Titre: #{existing_prime.titre}"
else
  puts '📝 Création de la Prime amiante...'

  # Créer la prime basée sur celle du développement
  amiante_prime = Prime.create!(
    titre: "Prime amiante",
    slug: "amiante",
    ordre_affichage: 50, # Mettre à la fin
    icon_name: "exclamation-triangle",
    unite: "€",
    type_de_valeur: "surface",
    region: "flandre",
    eligible_categories: ["1", "2", "3", "4"],
    condition: "Travaux de désamiantage obligatoires lors d'isolation",
    conseil: "Cette attestation doit toujours accompagner une attestation de toiture ou de mur.",
    document: "Attestation de l'entrepreneur spécialisé + certificat de désamiantage",
    échéances: "12 mois à partir de la date de facture de solde",
    specifique: "Obligatoire seulement si présence d'amiante détectée",
    category_id: Category.find_by(code: "categorie_4")&.id
  )

  puts "✅ Prime amiante créée!"
  puts "   ID: #{amiante_prime.id}"
  puts "   Titre: #{amiante_prime.titre}"
  puts "   Slug: #{amiante_prime.slug}"

  # Créer le document attestation_entrepreneur associé
  puts
  puts '📄 Création du document attestation_entrepreneur...'

  doc = PrimeDocumentTemplate.create!(
    prime: amiante_prime,
    type_document: 'attestation_entrepreneur',
    title: "L'attestation pour l'amiante (accompagne toujours une attestation de toiture ou de mur)",
    description: "Document obligatoire pour le désamiantage en combinaison avec isolation. Cette attestation ne se demande jamais seule et doit toujours accompagner une attestation de toiture ou de mur.",
    is_required: true,
    order_position: 8,
    file_url: "/data/prime_documents/amiante_attestation_entrepreneur.pdf"
  )

  puts "✅ Document créé!"
  puts "   ID: #{doc.id}"
  puts "   Titre: #{doc.title}"
end

# Vérification finale
puts
puts '🔍 Vérification finale:'

final_count = PrimeDocumentTemplate.joins(:prime)
                                  .where(primes: { region: 'flandre' }, type_document: 'attestation_entrepreneur')
                                  .count

puts "📊 Nombre total de documents attestation_entrepreneur Flandre: #{final_count}"

if final_count == 8
  puts '🎉 PARFAIT! Exactement 8 documents comme en développement!'
else
  puts "⚠️  Nombre actuel: #{final_count} (objectif: 8)"
end

puts
puts '✅ Script terminé avec succès!'
