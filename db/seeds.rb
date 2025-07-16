puts "🌱 Lancement du seed principal..."

# ➤ Primes - Flandre
flandre_path = Rails.root.join("db", "seeds", "flandre", "primes.rb")
if File.exist?(flandre_path)
  puts "🔹 Chargement de : #{flandre_path}"
  load flandre_path
end

# ➤ Catégories
categories_path = Rails.root.join("db", "seeds", "flandre", "categories.rb")
if File.exist?(categories_path)
  puts "🔹 Chargement de : #{categories_path}"
  load categories_path
end

# ➤ Propriétés de test
puts "🏠 Création de propriétés de test..."
user = User.first
if user
  # Bien en Wallonie
  wallonie_property = user.properties.find_or_create_by(rue: "Rue de l'Énergie", numero: "24") do |property|
    property.code_postal = "5000"
    property.commune = "Namur"
    property.region = "wallonie"
    property.type = "maison"
    property.type_propriete = "propriétaire complet"
    property.peb = "350"
    property.annee_construction = "1985"
  end
  puts "  ✅ Propriété Wallonie créée : #{wallonie_property.full_address}"

  # Bien en Flandre
  flandre_property = user.properties.find_or_create_by(rue: "Energiestraat", numero: "12") do |property|
    property.code_postal = "9000"
    property.commune = "Gent"
    property.region = "flandre"
    property.type = "appartement"
    property.type_propriete = "copropriétaire"
    property.peb = "280"
    property.annee_construction = "1995"
  end
  puts "  ✅ Propriété Flandre créée : #{flandre_property.full_address}"

  # Bien à Bruxelles
  bruxelles_property = user.properties.find_or_create_by(rue: "Rue de la Paix", numero: "8") do |property|
    property.code_postal = "1000"
    property.commune = "Bruxelles"
    property.region = "bruxelles"
    property.type = "maison"
    property.type_propriete = "propriétaire complet"
    property.peb = "400"
    property.annee_construction = "1970"
  end
  puts "  ✅ Propriété Bruxelles créée : #{bruxelles_property.full_address}"
else
  puts "  ⚠️  Aucun utilisateur trouvé, création de propriétés ignorée"
end

puts "✅ Seeds terminés"
