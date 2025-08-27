#!/usr/bin/env ruby

require_relative '../config/environment'

puts "🧪 Test de performance import BCE"
puts "=" * 40

# Mesurer le temps pour 100 entreprises
start_time = Time.current
sample_size = 100

puts "📊 Import de #{sample_size} entreprises..."

begin
  service = Entreprises::BrusselsBceImportService.new
  result = service.import_brussels_sample(sample_size)

  end_time = Time.current
  duration = end_time - start_time

  puts "\n✅ Résultats:"
  puts "- Importées: #{result[:imported]}"
  puts "- Ignorées: #{result[:skipped]}"
  puts "- Erreurs: #{result[:errors].size}"
  puts "- Durée: #{duration.round(2)} secondes"

  # Calculs de performance
  total_operations = result[:imported] * 4 # enterprise + denominations + addresses + activities
  ops_per_second = total_operations / duration

  puts "\n📈 Performance:"
  puts "- Opérations totales: #{total_operations}"
  puts "- Vitesse: #{ops_per_second.round(0)} opérations/seconde"

  # Extrapolation pour 144k
  target = 144_902
  estimated_duration = (target / sample_size) * duration

  puts "\n⏰ Extrapolation pour #{target} entreprises:"
  puts "- Temps estimé: #{(estimated_duration / 60).round(1)} minutes"
  puts "- Soit: #{(estimated_duration / 3600).round(1)} heures"

  # Taille base de données
  db_size_bytes = File.size(Rails.root.join('db', 'development.sqlite3'))
  db_size_mb = db_size_bytes / 1024.0 / 1024.0
  estimated_final_size = db_size_mb * (target / BceEnterprise.count)

  puts "\n💾 Taille base de données:"
  puts "- Actuelle: #{db_size_mb.round(1)} MB"
  puts "- Estimée finale: #{estimated_final_size.round(1)} MB"

rescue => e
  puts "❌ Erreur: #{e.message}"
  puts e.backtrace.first(5)
end
