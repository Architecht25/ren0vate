require './config/environment'

puts "🗺️  GÉOCODAGE EN LOT - PRODUCTION (Suite)"
puts "=" * 45

# Statistiques initiales
total_properties = Property.count
geocoded_properties = Property.where.not(latitude: nil).count
not_geocoded_properties = Property.where(latitude: nil).count

puts "📊 État actuel:"
puts "   Total: #{total_properties}"
puts "   Déjà géocodées: #{geocoded_properties}"
puts "   Restantes: #{not_geocoded_properties}"
puts

if not_geocoded_properties == 0
  puts "🎉 Toutes les propriétés sont géocodées !"
  exit
end

# Batch de 15 pour aller plus vite
BATCH_SIZE = 15

puts "🚀 Géocodage des #{[BATCH_SIZE, not_geocoded_properties].min} propriétés suivantes..."
puts

geocoded_count = 0
failed_count = 0
failed_addresses = []

Property.where(latitude: nil, longitude: nil).limit(BATCH_SIZE).each_with_index do |property, index|
  address = property.full_address
  print "#{index + 1}/#{[BATCH_SIZE, not_geocoded_properties].min} - #{address}... "
  
  begin
    if property.geocode
      property.update!(geocoded_at: Time.current)
      geocoded_count += 1
      puts "✅ OK (#{property.latitude.round(6)}, #{property.longitude.round(6)})"
    else
      failed_count += 1
      failed_addresses << address
      puts "❌ ÉCHEC"
    end
  rescue => e
    failed_count += 1
    failed_addresses << "#{address} (ERREUR: #{e.message})"
    puts "❌ ERREUR: #{e.message}"
  end
  
  # Pause réduite pour aller plus vite
  sleep(1) if index < [BATCH_SIZE, not_geocoded_properties].min - 1
end

puts
puts "🎉 BATCH TERMINÉ !"
puts "=" * 45
puts "✅ Réussites: #{geocoded_count}"
puts "❌ Échecs: #{failed_count}"

if failed_addresses.any?
  puts
  puts "❌ Adresses problématiques:"
  failed_addresses.each { |addr| puts "   - #{addr}" }
end

# Statistiques finales
final_geocoded = Property.where.not(latitude: nil).count
final_not_geocoded = Property.where(latitude: nil).count

puts
puts "📊 Bilan total:"
puts "   Géocodées: #{final_geocoded}/#{total_properties} (#{((final_geocoded.to_f / total_properties) * 100).round(1)}%)"
puts "   Restantes: #{final_not_geocoded}"

if final_not_geocoded > 0
  puts
  puts "💡 Pour continuer:"
  puts "   heroku run ruby geocode_batch.rb"
else
  puts
  puts "🎉 GÉOCODAGE TERMINÉ ! Toutes les propriétés sont localisées."
  puts "🗺️  Votre carte admin est maintenant complète !"
end