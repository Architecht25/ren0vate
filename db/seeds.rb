puts "🌱 Lancement du seed principal..."

# ➤ FLANDRE - Chargement des seeds
puts "\n🇳🇱 === FLANDRE ==="
flandre_categories_path = Rails.root.join("db", "seeds", "flandre", "categories.rb")
if File.exist?(flandre_categories_path)
  puts "🔹 Chargement de : #{flandre_categories_path}"
  load flandre_categories_path
end

flandre_primes_path = Rails.root.join("db", "seeds", "flandre", "primes.rb")
if File.exist?(flandre_primes_path)
  puts "🔹 Chargement de : #{flandre_primes_path}"
  load flandre_primes_path
end

# ➤ WALLONIE - Chargement des seeds
puts "\n🏴󠁢󠁥󠁷󠁡󠁬󠁿 === WALLONIE ==="
wallonie_categories_path = Rails.root.join("db", "seeds", "wallonie", "categories.rb")
if File.exist?(wallonie_categories_path)
  puts "🔹 Chargement de : #{wallonie_categories_path}"
  load wallonie_categories_path
end

wallonie_primes_path = Rails.root.join("db", "seeds", "wallonie", "primes.rb")
if File.exist?(wallonie_primes_path)
  puts "🔹 Chargement de : #{wallonie_primes_path}"
  load wallonie_primes_path
end

wallonie_audit_path = Rails.root.join("db", "seeds", "wallonie", "audit.rb")
if File.exist?(wallonie_audit_path)
  puts "🔹 Chargement de : #{wallonie_audit_path}"
  load wallonie_audit_path
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
