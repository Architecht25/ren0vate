# Script pour identifier et supprimer les doublons de factures
# Usage: heroku run rails runner scripts/clean_duplicate_factures.rb --app ren0vate

puts "🔍 Recherche des factures en double..."

# Récupérer toutes les factures
factures = Document.where(type_document: 'facture').includes(:property, :user)

puts "📊 Total de factures dans la base: #{factures.count}"

# Grouper par utilisateur
factures_by_user = factures.group_by(&:user_id)

puts "\n📋 Répartition par utilisateur:"
factures_by_user.each do |user_id, user_factures|
  user = User.find(user_id) if user_id
  puts "  Utilisateur: #{user&.email || 'Sans utilisateur'} (ID: #{user_id})"
  puts "    Total: #{user_factures.count} factures"

  # Grouper par propriété
  by_property = user_factures.group_by(&:property_id)
  by_property.each do |property_id, prop_factures|
    property = Property.find(property_id) if property_id
    puts "      Propriété: #{property&.address || 'Sans propriété'} (ID: #{property_id}) - #{prop_factures.count} factures"
  end
end

# Identifier les doublons potentiels (même nom de fichier)
puts "\n🔍 Identification des doublons potentiels (même nom de fichier)..."
duplicates_by_filename = factures.select { |f| f.file.attached? }
                                  .group_by { |f| f.file.filename.to_s }
                                  .select { |filename, docs| docs.count > 1 }

if duplicates_by_filename.any?
  puts "⚠️  Trouvé #{duplicates_by_filename.count} noms de fichiers en double:"
  duplicates_by_filename.each do |filename, docs|
    puts "\n  📄 #{filename} (#{docs.count} exemplaires)"
    docs.each do |doc|
      puts "      - ID: #{doc.id}, Créé: #{doc.created_at}, Propriété: #{doc.property_id}, Taille: #{doc.file_size_human}"
    end
  end
else
  puts "✅ Aucun doublon de nom de fichier trouvé"
end

# Identifier les doublons par date de création proche (moins de 1 minute)
puts "\n🔍 Identification des doublons par date de création proche..."
time_duplicates = []
sorted_factures = factures.sort_by(&:created_at)

sorted_factures.each_with_index do |facture, index|
  next if index == 0
  prev_facture = sorted_factures[index - 1]

  if facture.user_id == prev_facture.user_id &&
     facture.property_id == prev_facture.property_id &&
     (facture.created_at - prev_facture.created_at).abs < 60 # moins de 60 secondes

    if facture.file.attached? && prev_facture.file.attached? &&
       facture.file.filename.to_s == prev_facture.file.filename.to_s
      time_duplicates << [prev_facture, facture]
    end
  end
end

if time_duplicates.any?
  puts "⚠️  Trouvé #{time_duplicates.count} paires de doublons temporels:"
  time_duplicates.each do |older, newer|
    puts "\n  📄 #{older.file.filename}"
    puts "      - Plus ancien: ID #{older.id}, créé #{older.created_at}"
    puts "      - Plus récent: ID #{newer.id}, créé #{newer.created_at}"
  end
else
  puts "✅ Aucun doublon temporel trouvé"
end

puts "\n" + "="*80
puts "📊 RÉSUMÉ"
puts "="*80
puts "Total factures: #{factures.count}"
puts "Doublons de nom: #{duplicates_by_filename.values.flatten.count - duplicates_by_filename.count} documents"
puts "Doublons temporels: #{time_duplicates.flatten.count} documents"

# Proposer des options de suppression
puts "\n" + "="*80
puts "🗑️  OPTIONS DE SUPPRESSION"
puts "="*80
puts "\nPour supprimer un utilisateur spécifique:"
puts "  User.find(ID).documents.where(type_document: 'facture').destroy_all"
puts "\nPour supprimer une propriété spécifique:"
puts "  Property.find(ID).documents.where(type_document: 'facture').destroy_all"
puts "\nPour supprimer uniquement les doublons de nom de fichier (garder le plus récent):"
puts "  # Script disponible ci-dessous"

puts "\n⚠️  ATTENTION: Vérifiez bien les IDs avant de supprimer!"
