# Script de mise à jour des primes en production
# Mise à jour sécurisée des données condition/conseil des primes

puts "🚀 Mise à jour des primes en production..."

# Chargement des seeds de primes par région
begin
  puts "📋 Chargement des primes Wallonie..."
  load Rails.root.join('db', 'seeds', 'wallonie', 'primes', 'audit.rb')
  load Rails.root.join('db', 'seeds', 'wallonie', 'primes', 'toiture.rb')
  load Rails.root.join('db', 'seeds', 'wallonie', 'primes', 'murs.rb')
  load Rails.root.join('db', 'seeds', 'wallonie', 'primes', 'menuiseries.rb')
  load Rails.root.join('db', 'seeds', 'wallonie', 'primes', 'ventilation.rb')
  load Rails.root.join('db', 'seeds', 'wallonie', 'primes', 'chauffage.rb')
  load Rails.root.join('db', 'seeds', 'wallonie', 'primes', 'ecs.rb')
  load Rails.root.join('db', 'seeds', 'wallonie', 'primes', 'ameliorations_chauffage.rb')
  load Rails.root.join('db', 'seeds', 'wallonie', 'primes', 'installations.rb')
  puts "✅ Primes Wallonie mises à jour"

  puts "📋 Chargement des primes Flandre..."
  load Rails.root.join('db', 'seeds', 'flandre', 'primes.rb')
  puts "✅ Primes Flandre mises à jour"

rescue => e
  puts "❌ Erreur lors du chargement des primes: #{e.message}"
  puts e.backtrace.first(5)
end

puts ""
puts "🎉 Mise à jour des primes terminée !"
puts "📊 Statistiques après mise à jour:"
puts "  📋 Primes totales: #{Prime.count}"
puts "  ️  Wallonie: #{Prime.where(region: 'wallonie').count}"
puts "  🌊 Flandre: #{Prime.where(region: 'flandre').count}"
