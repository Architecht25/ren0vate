#!/usr/bin/env ruby

require_relative '../config/environment'
require 'csv'

puts "🔍 Diagnostic BCE Import Service"
puts "=" * 50

# Test 1: Vérification des modèles
puts "\n1. Test des modèles BCE:"
begin
  puts "  - BceEnterprise: #{BceEnterprise.count} entreprises"
  puts "  - BceDenomination: #{BceDenomination.count} dénominations"
  puts "  - BceAddress: #{BceAddress.count} adresses"
  puts "  - BceActivity: #{BceActivity.count} activités"
  puts "  ✅ Modèles OK"
rescue => e
  puts "  ❌ Erreur modèles: #{e.message}"
  exit 1
end

# Test 2: Vérification des fichiers CSV
puts "\n2. Test des fichiers CSV:"
csv_files = {
  enterprise: Rails.root.join('db', 'bce_data', 'enterprise.csv'),
  address: Rails.root.join('db', 'bce_data', 'address.csv'),
  denomination: Rails.root.join('db', 'bce_data', 'denomination.csv'),
  activity: Rails.root.join('db', 'bce_data', 'activity.csv')
}

csv_files.each do |name, path|
  if File.exist?(path)
    size_mb = File.size(path) / 1024.0 / 1024.0
    puts "  ✅ #{name}.csv: #{size_mb.round(1)} MB"
  else
    puts "  ❌ #{name}.csv: MANQUANT"
  end
end

# Test 3: Lecture du premier élément de chaque CSV
puts "\n3. Test lecture CSV:"
begin
  # Première ligne enterprise.csv
  CSV.foreach(csv_files[:enterprise], headers: true, quote_char: '"').with_index do |row, index|
    puts "  ✅ Enterprise sample: #{row['EnterpriseNumber']} - Status: #{row['Status']}"
    break if index >= 0
  end

  # Première ligne address.csv pour Bruxelles
  brussels_codes = %w[1000 1020 1030 1040 1050 1060 1070 1080 1081 1082 1083 1090 1120 1130 1140 1150 1160 1170 1180 1190 1200 1210]
  found_brussels = false

  CSV.foreach(csv_files[:address], headers: true, quote_char: '"').with_index do |row, index|
    if row['TypeOfAddress'] == 'REGO' && brussels_codes.include?(row['Zipcode'])
      puts "  ✅ Brussels address sample: #{row['EntityNumber']} - #{row['Zipcode']}"
      found_brussels = true
      break
    end
    break if index >= 1000 # Éviter de lire trop
  end

  unless found_brussels
    puts "  ⚠️  Aucune adresse Bruxelles trouvée dans les 1000 premières lignes"
  end

rescue => e
  puts "  ❌ Erreur lecture CSV: #{e.message}"
  puts "     #{e.backtrace.first}"
end

# Test 4: Test création entreprise simple
puts "\n4. Test création entreprise:"
begin
  test_number = "0999.999.999"

  # Supprimer si existe
  BceEnterprise.where(enterprise_number: test_number).destroy_all

  # Créer une entreprise test
  enterprise = BceEnterprise.create!(
    enterprise_number: test_number,
    status: "AC",
    juridical_situation: "000",
    type_of_enterprise: "2",
    juridical_form: "416",
    start_date: Date.today
  )

  puts "  ✅ Création entreprise test: ID #{enterprise.id}"

  # Nettoyer
  enterprise.destroy
  puts "  ✅ Nettoyage OK"

rescue => e
  puts "  ❌ Erreur création: #{e.message}"
  puts "     #{e.backtrace.first}"
end

puts "\n✅ Diagnostic terminé"
