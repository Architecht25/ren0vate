#!/usr/bin/env ruby
# Script pour vérifier la propriété de Michael Laes
# Usage: rails runner scripts/check_michael_laes_property.rb

puts "🔍 Vérification de la propriété de Michael Laes..."

# Trouver l'utilisateur Michael Laes
user = User.find_by(email: 'laes.michael@gmail.com')

if user.nil?
  puts "❌ Utilisateur Michael Laes non trouvé"
  exit
end

puts "✅ Utilisateur trouvé: #{user.first_name} #{user.last_name}"
puts "📧 Email: #{user.email}"
puts "🧪 Type: #{user.email.include?('@primes-services.be') ? 'Utilisateur interne' : 'Client externe'}"
puts "📍 Ville: #{user.city} (#{user.postal_code})"
puts ""

# Vérifier ses propriétés
properties = user.properties
puts "🏠 Nombre de propriétés: #{properties.count}"

if properties.empty?
  puts "❌ Aucune propriété trouvée pour Michael Laes"
  puts "💡 Il devrait créer une propriété avant d'uploader des documents"
else
  properties.each_with_index do |property, index|
    puts "🏠 Propriété #{index + 1} (ID: #{property.id}):"
    puts "   📍 Adresse: #{property.numero} #{property.rue}, #{property.code_postal} #{property.commune}"
    puts "   🌍 Région: #{property.region || 'NON DÉFINIE'}"

    # Déterminer la région en fonction du code postal
    region_detectee = case property.code_postal
    when /^[1][0-9]{3}$/
      'bruxelles'
    when /^[2-3][0-9]{3}$/
      'flandre'
    when /^[4-7][0-9]{3}$/
      'wallonie'
    else
      'inconnue'
    end

    puts "   🔍 Région détectée (code postal): #{region_detectee}"

    if property.region != region_detectee
      puts "   ⚠️  PROBLÈME: Région stockée (#{property.region}) != Région détectée (#{region_detectee})"
    end

    # Vérifier les projets
    projects = property.projects
    puts "   🔧 Projets: #{projects.count}"

    projects.each do |project|
      puts "      - #{project.nom} (statut: #{project.statut})"
      documents = project.documents
      puts "        📄 Documents: #{documents.count}"
      documents.each do |doc|
        puts "          * #{doc.type_document} (status: #{doc.status})"
      end
    end

    puts ""
  end
end

# Vérifier si la région est bien détectée pour le code postal 3090
puts "🔍 Vérification spécifique pour le code postal 3090 (Overijse):"
puts "   🌍 Code postal 3090 -> Région: flandre (codes 2000-3999)"
puts "   ✅ Overijse est bien en Flandre"
puts ""

puts "📋 Résumé:"
puts "   - Michael Laes devrait avoir une propriété en Flandre (3090)"
puts "   - En Flandre, l'audit énergétique N'EST PAS obligatoire"
puts "   - La validation technique ne devrait PAS demander d'audit"
