require './config/environment'

puts "🔧 CORRECTION AVENUE LOUISE"
puts "=" * 30

# Trouver toutes les Avenue Louise avec code postal incorrect
properties = Property.where("rue ILIKE ?", "%avenue louise%")

puts "Propriétés Avenue Louise trouvées:"
properties.each do |p|
  puts "- ID #{p.id}: #{p.full_address}"
  
  # Corriger si code postal incorrect
  if p.code_postal == "1050"
    p.update!(
      code_postal: "1000",
      commune: "Bruxelles",
      latitude: nil,
      longitude: nil,
      geocoded_at: nil
    )
    puts "  ✅ Corrigé → #{p.reload.full_address}"
  end
end

puts
puts "🎯 Maintenant testons le géocodage:"

# Tester une adresse Avenue Louise corrigée
test_property = properties.where(code_postal: "1000").first
if test_property
  puts "Test: #{test_property.full_address}"
  if test_property.geocode
    test_property.update!(geocoded_at: Time.current)
    puts "✅ Géocodage réussi: #{test_property.latitude}, #{test_property.longitude}"
  else
    puts "❌ Géocodage échoué"
  end
end