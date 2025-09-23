#!/usr/bin/env ruby
# Script pour mettre à jour les documents Wallonie avec les nouveaux documents Cloudinary
# Usage: rails runner scripts/update_wallonie_documents.rb

puts "🔧 Mise à jour des documents Wallonie avec les documents Cloudinary"
puts "=" * 80

# Mode simulation par défaut - changer à false pour exécution réelle
DRY_RUN = ENV['DRY_RUN'] != 'false'

if DRY_RUN
  puts "🚨 MODE SIMULATION - Aucune modification ne sera effectuée"
  puts "   Pour exécuter réellement: DRY_RUN=false rails runner scripts/update_wallonie_documents.rb"
else
  puts "⚡ MODE EXÉCUTION - Les modifications seront appliquées"
end

puts

# Configuration des 7 nouvelles attestations avec leurs URLs Cloudinary
NEW_ATTESTATIONS = {
  'ventilation' => {
    cloudinary_id: '13-03-2025_pdf-annexe-7-ventilation-primes-habitation_oxxorf',
    title: 'Attestation entrepreneur - Ventilation - Wallonie',
    description: 'Document obligatoire pour les travaux de ventilation (VMC simple flux, double flux)',
    primes_keywords: ['vmc', 'ventilation']
  },
  'menuiseries' => {
    cloudinary_id: '13-03-2025_pdf-annexe-4-menuiseries-exterieures-primes-habitation_uymsbn',
    title: 'Attestation entrepreneur - Menuiseries extérieures - Wallonie',
    description: 'Document obligatoire pour le remplacement des menuiseries et vitrages extérieurs',
    primes_keywords: ['menuiseries', 'vitrages', 'châssis']
  },
  'toiture' => {
    cloudinary_id: '13-03-2025_pdf-annexe-1-toiture-primes-habitation_rochbb',
    title: 'Attestation entrepreneur - Toiture - Wallonie',
    description: 'Document obligatoire pour tous les travaux de toiture (isolation, couverture, charpente)',
    primes_keywords: ['toiture', 'isolation_thermique', 'couverture', 'charpente']
  },
  'chauffage_ecs' => {
    cloudinary_id: '13-03-2025_pdf-annexe-6-installation-de-chauffage-et-ecs-primes-habitation_ylbxzh',
    title: 'Attestation entrepreneur - Installation de chauffage et ECS - Wallonie',
    description: 'Document obligatoire pour les installations de chauffage et eau chaude sanitaire',
    primes_keywords: ['chauffage', 'ecs', 'pompe', 'chaudiere', 'pac', 'ballon', 'circulateur', 'thermostat', 'vannes']
  },
  'gaz_electricite' => {
    cloudinary_id: '13-03-2025_pdf-annexe-5-gaz-electricite-radon-merule-primes-habitation_imn92l',
    title: 'Attestation entrepreneur - Gaz, électricité, radon, mérule - Wallonie',
    description: 'Document obligatoire pour les installations gaz/électricité et traitement radon/mérule',
    primes_keywords: ['gaz', 'electrique', 'radon', 'merule']
  },
  'sols' => {
    cloudinary_id: '13-03-2025_pdf-annexe-3-sols-primes-habitation_rykpl2',
    title: 'Attestation entrepreneur - Sols - Wallonie',
    description: 'Document obligatoire pour l\'isolation des sols et planchers',
    primes_keywords: ['sols', 'planchers', 'finition_planchers']
  },
  'murs' => {
    cloudinary_id: '13-03-2025_pdf-annexe-2-murs-primes-habitation_klxegb',
    title: 'Attestation entrepreneur - Murs - Wallonie',
    description: 'Document obligatoire pour l\'isolation et travaux sur les murs',
    primes_keywords: ['murs', 'assechement', 'renforcement']
  }
}

# Configuration des 2 formulaires de demande avec leurs URLs Cloudinary
NEW_FORMULAIRES = {
  'audit' => {
    cloudinary_id: '2025-02-13_prime_audit_grcjd3',
    title: 'Formulaire de demande - Prime audit énergétique - Wallonie',
    description: 'Formulaire officiel de demande pour la prime audit énergétique en Wallonie',
    prime_slug: 'wallonie_realisation_audit_logement'
  },
  'habitation_travaux' => {
    cloudinary_id: '2025-02-13_prime_habitation_travaux_2023_et_temporaire_2025_svl6fm',
    title: 'Formulaire de demande - Prime habitation travaux - Wallonie',
    description: 'Formulaire officiel de demande pour les primes habitation travaux 2023 et temporaire 2025 en Wallonie',
    prime_slug: 'wallonie_isolation_murs' # Prime de référence, sera utilisé pour toutes les primes de travaux
  }
}

# Générer les URLs Cloudinary complètes
def generate_cloudinary_url(cloudinary_id)
  "https://res.cloudinary.com/dtdelexhd/image/upload/#{cloudinary_id}.pdf"
end

# Récupérer toutes les attestations Wallonie existantes
existing_attestations = PrimeDocumentTemplate.joins(:prime)
                                            .where(primes: { region: 'wallonie' }, type_document: 'attestation_entrepreneur')
                                            .includes(:prime)

puts "📊 Situation actuelle:"
puts "- Attestations existantes: #{existing_attestations.count}"
puts

# Étape 1: Identifier quelles primes correspondent à chaque nouvelle attestation
puts "🎯 ÉTAPE 1: Attribution des primes aux nouvelles attestations"
puts "=" * 60

attestation_assignments = {}

NEW_ATTESTATIONS.each do |category, config|
  puts "📋 Catégorie: #{category.upcase}"
  puts "   Titre: #{config[:title]}"
  puts "   Mots-clés: #{config[:primes_keywords].join(', ')}"

  # Trouver les primes correspondantes
  matching_primes = []

  existing_attestations.each do |attestation|
    prime = attestation.prime
    prime_slug = prime.slug.downcase

    # Vérifier si le slug contient un des mots-clés
    if config[:primes_keywords].any? { |keyword| prime_slug.include?(keyword) }
      matching_primes << prime
      puts "     ✅ #{prime.titre} (#{prime.slug})"
    end
  end

  attestation_assignments[category] = {
    config: config,
    primes: matching_primes
  }

  puts "   Total primes: #{matching_primes.count}"
  puts
end

# Vérifier les primes non assignées
all_assigned_primes = attestation_assignments.values.flat_map { |data| data[:primes] }.uniq
unassigned_primes = existing_attestations.map(&:prime).uniq - all_assigned_primes

if unassigned_primes.any?
  puts "⚠️  PRIMES NON ASSIGNÉES (seront supprimées):"
  unassigned_primes.each do |prime|
    puts "  - #{prime.titre} (#{prime.slug})"
  end
  puts
end

puts
puts "🔧 ÉTAPE 2: Application des changements"
puts "=" * 60

created_count = 0
updated_count = 0
deleted_count = 0

if DRY_RUN
  puts "MODE SIMULATION - Voici ce qui serait fait:"
  puts
end

puts "📋 PARTIE A: Gestion des attestations d'entrepreneur"
puts "-" * 50

# Supprimer les documents non assignés
unassigned_attestations = existing_attestations.select { |att| unassigned_primes.include?(att.prime) }

unassigned_attestations.each do |attestation|
  if DRY_RUN
    puts "🗑️  [SIMULATION] Suppression: #{attestation.title}"
  else
    begin
      attestation.destroy!
      deleted_count += 1
      puts "🗑️  Supprimé: #{attestation.title}"
    rescue => e
      puts "❌ Erreur suppression ID #{attestation.id}: #{e.message}"
    end
  end
end

# Créer/Mettre à jour les nouvelles attestations
attestation_assignments.each do |category, data|
  config = data[:config]
  primes = data[:primes]

  if primes.empty?
    puts "⚠️  Aucune prime trouvée pour #{category}, création d'une attestation générale"
    # On peut soit créer une attestation générale, soit ignorer
    next
  end

  # Prendre la première prime comme référence (ou créer une logique plus sophistiquée)
  reference_prime = primes.first

  # Chercher une attestation existante pour cette prime
  existing_attestation = existing_attestations.find { |att| att.prime == reference_prime }

  cloudinary_url = generate_cloudinary_url(config[:cloudinary_id])

  if existing_attestation
    # Mettre à jour l'attestation existante
    if DRY_RUN
      puts "📝 [SIMULATION] Mise à jour: #{existing_attestation.title}"
      puts "     Nouveau titre: #{config[:title]}"
      puts "     Nouvelle URL: #{cloudinary_url}"
    else
      begin
        existing_attestation.update!(
          title: config[:title],
          description: config[:description],
          file_url: cloudinary_url,
          order_position: 1
        )
        updated_count += 1
        puts "📝 Mis à jour: #{config[:title]}"
      rescue => e
        puts "❌ Erreur mise à jour: #{e.message}"
      end
    end
  else
    # Créer une nouvelle attestation
    if DRY_RUN
      puts "➕ [SIMULATION] Création: #{config[:title]}"
      puts "     Prime: #{reference_prime.titre}"
      puts "     URL: #{cloudinary_url}"
    else
      begin
        PrimeDocumentTemplate.create!(
          prime: reference_prime,
          type_document: 'attestation_entrepreneur',
          title: config[:title],
          description: config[:description],
          file_url: cloudinary_url,
          is_required: true,
          order_position: 1
        )
        created_count += 1
        puts "➕ Créé: #{config[:title]}"
      rescue => e
        puts "❌ Erreur création: #{e.message}"
      end
    end
  end

  # Supprimer les attestations en double pour cette catégorie
  other_attestations = existing_attestations.select { |att| primes.include?(att.prime) && att != existing_attestation }
  other_attestations.each do |attestation|
    if DRY_RUN
      puts "🗑️  [SIMULATION] Suppression doublon: #{attestation.title}"
    else
      begin
        attestation.destroy!
        deleted_count += 1
        puts "🗑️  Supprimé doublon: #{attestation.title}"
      rescue => e
        puts "❌ Erreur suppression doublon: #{e.message}"
      end
    end
  end
end

puts
puts "📋 PARTIE B: Gestion des formulaires de demande"
puts "-" * 50

# Récupérer tous les formulaires existants pour la Wallonie
existing_formulaires = PrimeDocumentTemplate.joins(:prime)
                                           .where(primes: { region: 'wallonie' }, type_document: 'formulaire_demande')
                                           .includes(:prime)

puts "Formulaires existants: #{existing_formulaires.count}"

# Supprimer tous les formulaires existants
existing_formulaires.each do |formulaire|
  if DRY_RUN
    puts "🗑️  [SIMULATION] Suppression formulaire: #{formulaire.title}"
  else
    begin
      formulaire.destroy!
      deleted_count += 1
      puts "🗑️  Supprimé formulaire: #{formulaire.title}"
    rescue => e
      puts "❌ Erreur suppression formulaire: #{e.message}"
    end
  end
end

# Créer les nouveaux formulaires
NEW_FORMULAIRES.each do |category, config|
  # Trouver la prime de référence
  reference_prime = Prime.find_by(slug: config[:prime_slug])

  if reference_prime.nil?
    puts "⚠️  Prime non trouvée pour #{config[:prime_slug]}, ignoré"
    next
  end

  cloudinary_url = generate_cloudinary_url(config[:cloudinary_id])

  if DRY_RUN
    puts "➕ [SIMULATION] Création formulaire: #{config[:title]}"
    puts "     Prime: #{reference_prime.titre}"
    puts "     URL: #{cloudinary_url}"
  else
    begin
      PrimeDocumentTemplate.create!(
        prime: reference_prime,
        type_document: 'formulaire_demande',
        title: config[:title],
        description: config[:description],
        file_url: cloudinary_url,
        is_required: true,
        order_position: 2
      )
      created_count += 1
      puts "➕ Créé formulaire: #{config[:title]}"
    rescue => e
      puts "❌ Erreur création formulaire: #{e.message}"
    end
  end
end

puts
puts "📊 RÉSULTATS:"
puts "=" * 40

if DRY_RUN
  puts "MODE SIMULATION - Aucune modification appliquée"
  puts "Changements qui seraient effectués:"
else
  puts "MODIFICATIONS APPLIQUÉES:"
end

puts "- Documents créés: #{created_count}"
puts "- Documents mis à jour: #{updated_count}"
puts "- Documents supprimés: #{deleted_count}"

# Vérification finale
final_attestations = PrimeDocumentTemplate.joins(:prime)
                                         .where(primes: { region: 'wallonie' }, type_document: 'attestation_entrepreneur')

final_formulaires = PrimeDocumentTemplate.joins(:prime)
                                        .where(primes: { region: 'wallonie' }, type_document: 'formulaire_demande')

if DRY_RUN
  expected_attestations = NEW_ATTESTATIONS.count
  expected_formulaires = NEW_FORMULAIRES.count
  puts "- Attestations finales attendues: #{expected_attestations}"
  puts "- Formulaires finaux attendus: #{expected_formulaires}"
  puts "- Total documents attendus: #{expected_attestations + expected_formulaires}"
else
  puts "- Attestations finales: #{final_attestations.count}"
  puts "- Formulaires finaux: #{final_formulaires.count}"
  puts "- Total documents: #{final_attestations.count + final_formulaires.count}"

  if final_attestations.count == 7 && final_formulaires.count == 2
    puts "✅ SUCCÈS! Exactement 7 attestations + 2 formulaires comme souhaité"
  else
    puts "⚠️  ATTENTION: #{final_attestations.count} attestations + #{final_formulaires.count} formulaires"
    puts "              (attendu: 7 attestations + 2 formulaires)"
  end
end

puts
puts "🏁 Script terminé"
