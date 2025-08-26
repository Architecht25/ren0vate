#!/usr/bin/env ruby

require_relative '../config/environment'
require 'csv'

# Vérification des arguments
if ARGV.length != 1
  puts "Usage: #{$0} <enterprise_number>"
  puts "Exemple: #{$0} 0833.618.097"
  exit 1
end

enterprise_number = ARGV[0]
puts "🔍 Import des données pour l'entreprise #{enterprise_number}..."

begin
  # 1. Import de l'entreprise
  enterprise_file = Rails.root.join('db', 'bce_data', 'enterprise.csv')
  if File.exist?(enterprise_file)
    CSV.foreach(enterprise_file, headers: false, encoding: 'UTF-8') do |row|
      if row[0] == enterprise_number
        enterprise = BceEnterprise.find_or_create_by(enterprise_number: row[0]) do |e|
          e.status = row[1]
          e.juridical_situation = row[2]
          e.type_of_enterprise = row[3]
          e.juridical_form = row[4]
          e.start_date = Date.parse(row[6]) if row[6] && !row[6].empty?
        end
        puts "✅ Entreprise importée: #{enterprise.enterprise_number}"
        break
      end
    end
  end

  # 2. Import des dénominations
  denomination_file = Rails.root.join('db', 'bce_data', 'denomination.csv')
  if File.exist?(denomination_file)
    CSV.foreach(denomination_file, headers: false, encoding: 'UTF-8') do |row|
      if row[0] == enterprise_number
        denomination = BceDenomination.find_or_create_by(
          enterprise_number: row[0],
          language_code: row[1],
          type_of_denomination: row[2]
        ) do |d|
          d.denomination = row[3]
        end
        puts "✅ Dénomination importée: #{denomination.denomination}"
      end
    end
  end

  # 3. Import des adresses
  address_file = Rails.root.join('db', 'bce_data', 'address.csv')
  if File.exist?(address_file)
    CSV.foreach(address_file, headers: false, encoding: 'UTF-8') do |row|
      if row[0] == enterprise_number
        address = BceAddress.find_or_create_by(
          enterprise_number: row[0],
          type_of_address: row[1]
        ) do |a|
          a.country_nl = row[2]
          a.country_fr = row[3]
          a.zipcode = row[4]
          a.municipality_nl = row[5]
          a.municipality_fr = row[6]
          a.street_nl = row[7]
          a.street_fr = row[8]
          a.house_number = row[9]
          a.box = row[10]
          a.extra_address_info = row[11]
        end
        puts "✅ Adresse importée: #{address.street_fr || address.street_nl} #{address.house_number}, #{address.zipcode} #{address.municipality_fr || address.municipality_nl}"
      end
    end
  end

  # 4. Import des activités
  activity_file = Rails.root.join('db', 'bce_data', 'activity.csv')
  if File.exist?(activity_file)
    CSV.foreach(activity_file, headers: false, encoding: 'UTF-8') do |row|
      if row[0] == enterprise_number
        activity = BceActivity.find_or_create_by(
          enterprise_number: row[0],
          activity_group: row[1],
          nace_version: row[2],
          nace_code: row[3]
        ) do |a|
          a.classification = row[4]
        end
        puts "✅ Activité importée: NACE #{activity.nace_code} (#{activity.classification})"
      end
    end
  end

  puts "\n🎉 Import terminé pour l'entreprise #{enterprise_number}!"

rescue => e
  puts "❌ Erreur lors de l'import: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
