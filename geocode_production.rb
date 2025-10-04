require './config/environment'

puts "🗺️  GÉOCODAGE EN LOT - PRODUCTION"
puts "=" * 40

# Statistiques initiales
total_properties = Property.count
geocoded_properties = Property.where.not(latitude: nil).count
not_geocoded_properties = Property.where(latitude: nil).count

puts "📊 Propriétés en production:"
puts "   Total: #{total_properties}"
puts "   Déjà géocodées: #{geocoded_properties}"
puts "   À géocoder: #{not_geocoded_properties}"
puts

if not_geocoded_properties == 0
  puts "✅ Toutes les propriétés sont géocodées !"
  exit
end

# Limite pour éviter de surcharger l'API en production
BATCH_SIZE = 10

puts "🚀 Géocodage des #{[BATCH_SIZE, not_geocoded_properties].min} premières propriétés..."
puts

geocoded_count = 0
failed_count = 0

Property.where(latitude: nil, longitude: nil).limit(BATCH_SIZE).each_with_index do |property, index|
  print "#{index + 1}/#{[BATCH_SIZE, not_geocoded_properties].min} - #{property.full_address}... "
  
  begin
    if property.geocode
      property.update!(geocoded_at: Time.current)
      geocoded_count += 1
      puts "✅ OK (#{property.latitude.round(6)}, #{property.longitude.round(6)})"
    else
      failed_count += 1
      puts "❌ ÉCHEC"
    end
  rescue => e
    failed_count += 1
    puts "❌ ERREUR: #{e.message}"
  end
  
  # Pause pour respecter les limites de l'API
  sleep(1.5) if index < [BATCH_SIZE, not_geocoded_properties].min - 1
end

puts
puts "🎉 BATCH TERMINÉ !"
puts "=" * 40
puts "✅ Réussites: #{geocoded_count}"
puts "❌ Échecs: #{failed_count}"

# Statistiques finales
final_geocoded = Property.where.not(latitude: nil).count
final_not_geocoded = Property.where(latitude: nil).count

puts
puts "📊 Après ce batch:"
puts "   Géocodées: #{final_geocoded}/#{total_properties}"
puts "   Restantes: #{final_not_geocoded}"

if final_not_geocoded > 0
  puts
  puts "💡 Pour géocoder le reste:"
  puts "   heroku run ruby geocode_production.rb"
end