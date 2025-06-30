puts "🌱 Lancement du seed principal..."

path = Rails.root.join("db", "seeds", "flandre", "primes.rb")
if File.exist?(path)
  puts "🔹 Chargement de : #{path}"
  load path
end

puts "✅ Seeds terminés"
