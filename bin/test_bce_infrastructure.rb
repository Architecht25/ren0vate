#!/usr/bin/env ruby

require_relative '../config/environment'

puts "🔍 Test BCE Infrastructure"
puts "=" * 50

# Test 1: Vérification des modèles
puts "\n1. Test des modèles BCE:"
puts "  - BceEnterprise: #{BceEnterprise.count} entreprises"
puts "  - BceDenomination: #{BceDenomination.count} dénominations"
puts "  - BceAddress: #{BceAddress.count} adresses"
puts "  - BceActivity: #{BceActivity.count} activités"

# Test 2: Test d'une entreprise
puts "\n2. Test d'affichage d'une entreprise:"
enterprise = BceEnterprise.first
if enterprise
  puts "  🏢 Numéro: #{enterprise.enterprise_number}"
  puts "  📊 Statut: #{enterprise.status} (#{enterprise.status == 'AC' ? 'Actif' : enterprise.status})"

  # Test des associations
  denomination = enterprise.bce_denominations.first
  puts "  🏷️  Dénomination: #{denomination&.denomination || 'Aucune'}"

  address = enterprise.bce_addresses.first
  if address
    street = address.street_fr || address.street_nl || 'N/A'
    city = address.municipality_fr || address.municipality_nl || 'N/A'
    puts "  📍 Adresse: #{street} #{address.house_number}, #{address.zipcode} #{city}"
  else
    puts "  📍 Adresse: Aucune"
  end

  puts "  🎯 Activités: #{enterprise.bce_activities.count}"
else
  puts "  ❌ Aucune entreprise trouvée"
end

# Test 3: Test de recherche par numéro
puts "\n3. Test de recherche par numéro:"
test_number = enterprise&.enterprise_number || '0200.065.765'
found = BceEnterprise.find_by_number(test_number)
puts "  Recherche '#{test_number}': #{found ? '✅ Trouvée' : '❌ Non trouvée'}"

puts "\n✨ Test terminé!"
