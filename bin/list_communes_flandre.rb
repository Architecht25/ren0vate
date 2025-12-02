#!/usr/bin/env ruby

# Script pour lister les communes de Flandre avec des utilisateurs
# Usage: rails runner bin/list_communes_flandre.rb
# Ou sur Heroku: heroku run "rails runner bin/list_communes_flandre.rb" --app ren0vate

puts "🇧🇪 COMMUNES DE FLANDRE - REN0VATE"
puts "=" * 50
puts "📅 Date: #{Time.current.strftime('%d/%m/%Y %H:%M')}"
puts ""

begin
  # Récupération des communes de Flandre avec comptage
  communes_stats = Property.where(region: 'flandre')
                          .group(:commune)
                          .count
                          .sort_by { |commune, count| -count }

  if communes_stats.empty?
    puts "❌ Aucune propriété trouvée en Flandre"
    exit
  end

  puts "📊 STATISTIQUES GÉNÉRALES"
  puts "-" * 30
  puts "Nombre total de communes: #{communes_stats.count}"
  total_properties = communes_stats.map { |_, count| count }.sum
  puts "Nombre total de propriétés: #{total_properties}"

  # Compter les utilisateurs uniques
  unique_users = Property.joins(:user)
                        .where(region: 'flandre')
                        .distinct
                        .count(:user_id)
  puts "Nombre d'utilisateurs uniques: #{unique_users}"
  puts ""

  puts "📍 COMMUNES PAR ORDRE DÉCROISSANT"
  puts "-" * 40

  communes_stats.each_with_index do |(commune, count), index|
    # Récupérer quelques détails supplémentaires
    users_count = Property.joins(:user)
                         .where(region: 'flandre', commune: commune)
                         .distinct
                         .count(:user_id)

    puts "#{(index + 1).to_s.rjust(2)}. #{commune.ljust(25)} | #{count.to_s.rjust(3)} propriétés | #{users_count.to_s.rjust(3)} utilisateurs"
  end

  puts ""
  puts "📋 LISTE ALPHABÉTIQUE DES COMMUNES"
  puts "-" * 40

  communes_alphabetical = communes_stats.map { |commune, _| commune }.sort
  communes_alphabetical.each_with_index do |commune, index|
    puts "#{(index + 1).to_s.rjust(2)}. #{commune}"
  end

  puts ""
  puts "🎯 TOP 10 DES COMMUNES"
  puts "-" * 25

  top_10 = communes_stats.first(10)
  total_properties = communes_stats.map { |_, count| count }.sum
  top_10.each_with_index do |(commune, count), index|
    percentage = (count.to_f / total_properties * 100).round(1)
    puts "#{(index + 1).to_s.rjust(2)}. #{commune.ljust(20)} #{count.to_s.rjust(3)} (#{percentage}%)"
  end

  puts ""
  puts "💾 EXPORT CSV"
  puts "-" * 15

  csv_content = "Commune,Propriétés,Utilisateurs\n"
  communes_stats.each do |commune, count|
    users_count = Property.joins(:user)
                         .where(region: 'flandre', commune: commune)
                         .distinct
                         .count(:user_id)
    csv_content += "#{commune},#{count},#{users_count}\n"
  end

  puts csv_content
  puts ""

  # Détails par province si possible (basé sur les codes postaux)
  puts "🗺️  RÉPARTITION PAR PROVINCE (estimation basée sur codes postaux)"
  puts "-" * 60

  provinces = {
    'Anvers' => (2000..2999),
    'Limbourg' => (3500..3999),
    'Flandre-Orientale' => (9000..9999),
    'Flandre-Occidentale' => (8000..8999),
    'Brabant flamand' => (1500..1999).to_a + (3000..3499).to_a
  }

  provinces.each do |province, postal_codes|
    if postal_codes.is_a?(Range)
      properties_count = Property.where(region: 'flandre')
                                .where(code_postal: postal_codes.map(&:to_s))
                                .count
    else
      properties_count = Property.where(region: 'flandre')
                                .where(code_postal: postal_codes.map(&:to_s))
                                .count
    end

    if properties_count > 0
      communes_in_province = Property.where(region: 'flandre')
                                   .where(code_postal: postal_codes.map(&:to_s))
                                   .distinct
                                   .pluck(:commune)
                                   .compact
                                   .sort

      puts "#{province}: #{properties_count} propriétés"
      puts "  Communes: #{communes_in_province.join(', ')}" if communes_in_province.any?
      puts ""
    end
  end

rescue => e
  puts "❌ Erreur lors de l'exécution: #{e.message}"
  puts e.backtrace.first(5)
end

puts "✅ Analyse terminée"
