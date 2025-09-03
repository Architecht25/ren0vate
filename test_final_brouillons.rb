#!/usr/bin/env ruby

# Test complet du système de brouillons
require 'bundler/setup'
require_relative 'config/environment'

puts "🚀 Test complet du système de brouillons"
puts "=" * 50

user = User.first
if user.nil?
  puts "❌ ERREUR: Aucun utilisateur trouvé"
  exit 1
end

puts "👤 Utilisateur: #{user.email}"

# Test 1: Création d'un brouillon avec données minimales
puts "\n📝 Test 1: Création d'un brouillon avec données minimales"
request = Request.new(
  user: user,
  title: '',  # Sera remplacé par défaut
  description: '',  # Sera remplacé par défaut
  region: 'wallonie',
  status: 'draft'
)

if request.save
  puts "✅ Brouillon créé avec succès - ID: #{request.id}"
  puts "   Titre: '#{request.title}'"
  puts "   Description: '#{request.description}'"
  puts "   Statut: #{request.status}"
else
  puts "❌ Échec: #{request.errors.full_messages.join(', ')}"
end

# Test 2: Mise à jour du brouillon avec des données partielles
if request.persisted?
  puts "\n🔄 Test 2: Mise à jour du brouillon avec données partielles"
  request.title = "Mon projet de rénovation"
  request.nom = "Dupont"  # Partiel seulement
  # Laisser d'autres champs vides intentionnellement

  if request.save
    puts "✅ Brouillon mis à jour avec succès"
    puts "   Titre: '#{request.title}'"
    puts "   Nom: '#{request.nom}'"
    puts "   Prénom: '#{request.prenom}'"  # Devrait être vide
  else
    puts "❌ Échec de mise à jour: #{request.errors.full_messages.join(', ')}"
  end
end

# Test 3: Tentative de soumission avec données incomplètes (devrait échouer)
if request.persisted?
  puts "\n📤 Test 3: Tentative de soumission avec données incomplètes"
  request.status = 'submitted'

  if request.save
    puts "⚠️  ATTENTION: La soumission a réussi alors qu'elle ne devrait pas!"
  else
    puts "✅ CORRECT: Soumission refusée - #{request.errors.count} erreur(s)"
    # Remettre en brouillon
    request.status = 'draft'
    request.save
  end
end

# Test 4: Compléter les données et soumettre
if request.persisted?
  puts "\n✅ Test 4: Complétion et soumission du brouillon"
  request.assign_attributes({
    description: "Isolation de la toiture et remplacement des fenêtres",
    revenus_reference: 45000,
    composition_menage: "2 adultes + 1 enfant",
    categories_travaux: "isolation",
    logement_principal: true,
    montant_travaux: 15000.0,
    status: 'submitted'
  })

  if request.save
    puts "✅ Demande soumise avec succès!"
    puts "   Statut final: #{request.status}"
  else
    puts "❌ Échec de soumission: #{request.errors.full_messages.join(', ')}"
    puts "   Erreurs par champ:"
    request.errors.each do |error|
      puts "     - #{error.attribute}: #{error.message}"
    end
  end
end

# Résumé final
puts "\n📊 Résumé final"
puts "=" * 30
drafts_count = Request.where(status: 'draft').count
submitted_count = Request.where(status: 'submitted').count
puts "Brouillons en base: #{drafts_count}"
puts "Demandes soumises: #{submitted_count}"

puts "\n🎉 Test terminé avec succès!"
