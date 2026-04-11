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

# ➤ PHASES DE DOCUMENTS - Chargement des seeds
puts "\n📋 === PHASES DE DOCUMENTS ==="
document_phases_path = Rails.root.join("db", "seeds", "document_phases.rb")
if File.exist?(document_phases_path)
  puts "🔹 Chargement de : #{document_phases_path}"
  load document_phases_path
end

# ➤ DOCUMENTS OFFICIELS - Chargement des seeds
puts "\n📋 === DOCUMENTS OFFICIELS ==="
prime_documents_path = Rails.root.join("db", "seeds", "prime_documents.rb")
if File.exist?(prime_documents_path)
  puts "🔹 Chargement de : #{prime_documents_path}"
  load prime_documents_path
end

# ➤ PRODUITS & MATÉRIAUX - Comparateur
puts "\n🔬 === PRODUITS & MATÉRIAUX ==="
products_path = Rails.root.join("db", "seeds", "products.rb")
if File.exist?(products_path)
  puts "🔹 Chargement de : #{products_path}"
  load products_path
end

puts "✅ Seeds terminés"
