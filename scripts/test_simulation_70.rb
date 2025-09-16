#!/usr/bin/env ruby
# Test spécifique pour la simulation 70

require_relative '../config/environment'

puts "🧪 TEST SPÉCIFIQUE - Simulation 70"
puts "=" * 40

simulation = Simulation.find(70)

puts "📊 État de la simulation :"
puts "   ID: #{simulation.id}"
puts "   Titre: #{simulation.titre}"
puts "   Région: #{simulation.region}"
puts "   Total: #{simulation.total_simule}€"

if simulation.parameters.present?
  params_data = JSON.parse(simulation.parameters)

  puts "\n📝 Saisies utilisateur actives :"
  count = 0
  params_data['prime_cards'].each do |category_key, category_data|
    next unless category_data['primes']

    puts "   Catégorie #{category_key}:"
    category_data['primes'].each do |prime|
      if prime['user_input_value'].present? && prime['user_input_value'] != 0 && prime['user_input_value'] != "0"
        puts "     #{prime['slug']}: #{prime['user_input_value']} (#{prime['calculated_amount']}€)"
        count += 1
      end
    end
  end

  puts "\n📈 Totaux par catégorie :"
  params_data['prime_cards'].each do |category_key, category_data|
    puts "   #{category_key}: #{category_data['total']}€"
  end

  puts "\n💰 Total général: #{params_data['total_general']}€"
  puts "📅 Dernière mise à jour: #{params_data['last_update']}"

  puts "\n🔍 Diagnostic interface Flandre :"
  puts "   Les slugs utilisés sont-ils compatibles Flandre ?"

  flandre_compatible_slugs = []
  other_slugs = []

  params_data['prime_cards'].each do |category_key, category_data|
    next unless category_data['primes']

    category_data['primes'].each do |prime|
      if prime['user_input_value'].present? && prime['user_input_value'] != 0
        slug = prime['slug']
        if slug.match?(/^(isolation_|ramen_|warmte|voorbereiding_|renovation_)/)
          flandre_compatible_slugs << slug
        else
          other_slugs << slug
        end
      end
    end
  end

  puts "   ✅ Slugs compatibles Flandre (#{flandre_compatible_slugs.length}):"
  flandre_compatible_slugs.each { |slug| puts "     #{slug}" }

  if other_slugs.any?
    puts "   ❌ Slugs incompatibles (#{other_slugs.length}):"
    other_slugs.each { |slug| puts "     #{slug}" }
    puts "   ⚠️  Ces slugs ne seront pas restaurés dans l'interface Flandre"
  else
    puts "   🎉 Tous les slugs sont compatibles Flandre !"
  end

  puts "\n💡 Instructions :"
  puts "   1. Visitez: http://localhost:3000/simulations/70"
  puts "   2. Ouvrez la console développeur (F12)"
  puts "   3. Vérifiez les messages de restauration Flandre"
  puts "   4. Les inputs devraient se remplir automatiquement"
  puts "   5. Le total devrait afficher #{simulation.total_simule}€"
else
  puts "\n❌ Aucun paramètre trouvé !"
end
