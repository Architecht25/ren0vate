#!/usr/bin/env ruby
require_relative '../config/environment'

# Test import d'une seule entreprise
entity_number = "0220.819.807"  # Une des dernières importées

puts "🔍 Test import entreprise: #{entity_number}"
puts ""

service = Entreprises::BrusselsBceImportService.new

# Vérifier si l'entreprise existe déjà
if BceEnterprise.exists?(enterprise_number: entity_number)
  puts "⚠️  Entreprise déjà en base, suppression pour test..."
  enterprise = BceEnterprise.find_by(enterprise_number: entity_number)
  enterprise.bce_addresses.destroy_all
  enterprise.bce_denominations.destroy_all
  enterprise.bce_activities.destroy_all
  enterprise.destroy
end

# Import
begin
  puts "🚀 Import en cours..."
  service.send(:import_single_enterprise, entity_number)

  # Vérification
  enterprise = BceEnterprise.find_by(enterprise_number: entity_number)
  if enterprise
    puts "✅ Entreprise créée:"
    puts "   - Numéro: #{enterprise.enterprise_number}"
    puts "   - Status: #{enterprise.status}"
    puts "   - Adresses: #{enterprise.bce_addresses.count}"
    puts "   - Dénominations: #{enterprise.bce_denominations.count}"
    puts "   - Activités: #{enterprise.bce_activities.count}"

    if enterprise.bce_addresses.any?
      puts ""
      puts "📍 Adresses:"
      enterprise.bce_addresses.each do |addr|
        puts "   - #{addr.type_of_address}: #{addr.zipcode} #{addr.municipality_fr}"
      end
    end

    if enterprise.bce_denominations.any?
      puts ""
      puts "🏢 Dénominations:"
      enterprise.bce_denominations.each do |denom|
        puts "   - #{denom.language}: #{denom.denomination}"
      end
    end
  else
    puts "❌ Entreprise non trouvée après import"
  end

rescue => e
  puts "❌ Erreur: #{e.message}"
  puts e.backtrace.first(3)
end
