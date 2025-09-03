#!/usr/bin/env ruby

# Test de création de brouillon
require 'bundler/setup'
require_relative 'config/environment'

puts "Test de création de brouillon avec données incomplètes..."

user = User.first
if user.nil?
  puts "ERREUR: Aucun utilisateur trouvé dans la base de données"
  exit 1
end

puts "Utilisateur trouvé: #{user.email}"

# Test 1: Brouillon avec données minimales
puts "\n=== Test 1: Brouillon avec données minimales ==="
request1 = Request.new(
  user: user,
  title: 'Test brouillon 1',
  description: '',  # Vide
  region: 'flandre',
  status: 'draft',
  nom: '',          # Vide (requis pour Flandre normalement)
  prenom: ''        # Vide (requis pour Flandre normalement)
)

if request1.save
  puts "✅ SUCCÈS: Brouillon sauvegardé avec ID: #{request1.id}"
  puts "   Status: #{request1.status}"
  puts "   Titre: #{request1.title}"
  puts "   Description: \"#{request1.description}\""
  puts "   Nom: \"#{request1.nom}\""
  puts "   Région: #{request1.region}"
else
  puts "❌ ÉCHEC: #{request1.errors.full_messages.join(', ')}"
end

# Test 2: Tentative de soumission finale avec mêmes données (devrait échouer)
puts "\n=== Test 2: Tentative de soumission finale avec données incomplètes ==="
request2 = Request.new(
  user: user,
  title: 'Test soumission',
  description: '',  # Vide
  region: 'flandre',
  status: 'submitted',  # Pas un brouillon
  nom: '',              # Vide (requis pour Flandre)
  prenom: ''            # Vide (requis pour Flandre)
)

if request2.save
  puts "⚠️  ATTENTION: La soumission a réussi alors qu'elle ne devrait pas!"
else
  puts "✅ CORRECT: Soumission échouée comme attendu: #{request2.errors.full_messages.join(', ')}"
end

# Test 3: Modification d'un brouillon existant en soumission
if request1.persisted?
  puts "\n=== Test 3: Passage d'un brouillon en soumission ==="
  request1.status = 'submitted'
  if request1.save
    puts "⚠️  ATTENTION: Le passage en soumission a réussi avec des données incomplètes!"
  else
    puts "✅ CORRECT: Le passage en soumission a échoué: #{request1.errors.full_messages.join(', ')}"
  end
end

puts "\n=== Tests terminés ==="
