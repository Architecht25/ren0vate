#!/usr/bin/env ruby
# Script de test pour la fonctionnalité de comparaison d'économies pour les entreprises

puts "🏢 Test des économies pour entreprises Bruxelles"
puts "=" * 50

# Simuler différents montants d'aides pour tester les seuils
test_amounts = [10000, 25000, 50000, 100000, 200000]

test_amounts.each do |amount|
  puts "\n💰 Test avec #{amount}€ d'aides estimées (Entreprise Bruxelles)"
  
  # Service de calcul avec type 'entreprise'
  calculator = SavingsCalculatorService.new(amount, 'bruxelles', 'entreprise')
  result = calculator.calculate_savings
  
  if result
    puts "  📋 Détails du calcul:"
    puts "    Coût chasseur traditionnel: #{result[:chasseur_cost].round(2)}€"
    puts "    Coût abonnement Ren0vate Pro: #{result[:saas_cost].round(2)}€"
    puts "    Économies réalisées: #{result[:savings_amount].round(2)}€"
    puts "    Pourcentage d'économie: #{result[:savings_percentage]}%"
    puts "    Affichage significatif: #{calculator.significant_savings? ? '✅ OUI' : '❌ NON'}"
    puts "    Détails abonnement: #{result[:subscription_details][:monthly_price]}€/mois × #{result[:subscription_details][:duration_months]} mois"
    puts "    Type de client: #{result[:client_type]}"
  else
    puts "  ❌ Erreur de calcul"
  end
  
  puts "  " + "-" * 40
end

puts "\n🎯 Seuils d'affichage:"
puts "  Particuliers: 250€"
puts "  Entreprises: 500€"

puts "\n📊 Tarification Entreprise:"
puts "  Bruxelles: 59.99€/mois × 24 mois = #{59.99 * 24}€"
puts "  Wallonie/Flandre: 49.99€/mois × 36 mois = #{49.99 * 36}€"

puts "\n✅ Test terminé !"