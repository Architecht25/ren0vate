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

puts "✅ Seeds terminés"
