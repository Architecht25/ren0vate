puts "🌱 Lancement du seed principal..."

# ➤ UTILISATEURS PRODUCTION - Chargement des seeds
puts "\n👥 === UTILISATEURS PRODUCTION ==="
users_production_path = Rails.root.join("db", "seeds", "users_production.rb")
if File.exist?(users_production_path)
  puts "🔹 Chargement de : #{users_production_path}"
  load users_production_path
end

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

# ➤ BRUXELLES - Chargement des seeds
puts "\n🏢 === BRUXELLES ==="
bruxelles_categories_path = Rails.root.join("db", "seeds", "bruxelles", "categories.rb")
if File.exist?(bruxelles_categories_path)
  puts "🔹 Chargement de : #{bruxelles_categories_path}"
  load bruxelles_categories_path
end

bruxelles_primes_path = Rails.root.join("db", "seeds", "bruxelles", "primes.rb")
if File.exist?(bruxelles_primes_path)
  puts "🔹 Chargement de : #{bruxelles_primes_path}"
  load bruxelles_primes_path
end

# ➤ Propriétés de test
puts "🏠 Création de propriétés de test..."

# Mode intelligent : choisir un utilisateur approprié selon l'environnement
if Rails.env.development?
  # En développement : créer ou utiliser Robin
  user = User.find_or_create_by(email: 'robin@primes-services.be') do |u|
    u.password = 'password123'
    u.password_confirmation = 'password123'
    u.nom = 'Robin'
  end
  puts "  👤 Utilisateur de développement : #{user.email}"
elsif Rails.env.production?
  # En production : utiliser Robin si il existe, sinon prendre le plus actif
  user = User.find_by(email: 'robin@primes-services.be') ||
         User.joins(:properties).group('users.id').order('COUNT(properties.id) DESC').first ||
         User.order(created_at: :desc).first
  puts "  👤 Utilisateur production sélectionné : #{user&.email&.gsub(/.{3,}@/, '***@') || 'aucun'}"
else
  # Autres environnements : essayer Robin puis fallback
  user = User.find_by(email: 'robin@primes-services.be') || User.first
  puts "  👤 Utilisateur sélectionné : #{user&.email || 'aucun'}"
end
if user && (Rails.env.development? || ENV['CREATE_TEST_PROPERTIES'] == 'true')
  puts "  🏗️  Création des propriétés de test..."
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
elsif user && Rails.env.production?
  puts "  🔒 Mode production : propriétés de test non créées (utilisez CREATE_TEST_PROPERTIES=true si nécessaire)"
else
  puts "  ⚠️  Aucun utilisateur trouvé, création de propriétés ignorée"
end

puts "✅ Seeds terminés"

# ➤ AIDES AUX ENTREPRISES - Chargement des seeds
puts "\n🏢 === AIDES AUX ENTREPRISES ==="
entreprises_bruxelles_path = Rails.root.join("db", "seeds", "entreprises", "bruxelles", "aides.rb")
if File.exist?(entreprises_bruxelles_path)
  puts "🔹 Chargement de : #{entreprises_bruxelles_path}"
  load entreprises_bruxelles_path
end
