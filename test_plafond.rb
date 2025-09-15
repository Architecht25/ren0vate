aide = EntrepriseAide.find_by(slug: "bruxelles_prime_digitalisation")
puts "🧪 Test Prime Digitalisation:"
puts "Plafond: #{aide.montant_max}€, Taux: #{aide.taux_aide}%"
puts

[10_000, 20_000, 40_000, 50_000, 100_000].each do |montant|
  prime_brute = montant * (aide.taux_aide / 100.0)
  prime_finale = [prime_brute, aide.montant_max].min
  plafond_atteint = prime_brute > aide.montant_max

  puts "#{montant.to_s.rjust(9)}€ → #{prime_brute.round.to_s.rjust(6)}€ → #{prime_finale.round.to_s.rjust(6)}€ #{plafond_atteint ? 'PLAFOND!' : ''}"
end
