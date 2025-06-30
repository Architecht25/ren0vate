puts "🌱 Lancement du seed principal..."

%w[flandre wallonie bruxelles].each do |region|
  path = Rails.root.join("db", "seeds", region, "primes.rb")
  if File.exist?(path)
    puts "🔹 Chargement de : #{path}"
    load path
  end
end

puts "✅ Seeds terminés"
