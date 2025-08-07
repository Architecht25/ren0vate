namespace :primes do
  desc "Mise à jour des primes bonus Z1-Z10 pour Bruxelles"
  task update_bonus_z1_z10: :environment do
    puts "🔄 Mise à jour des primes bonus Z1-Z10..."

    # Seulement les nouvelles primes bonus
    bonus_primes = [
      "bruxelles_prime_bonus_z1",
      "bruxelles_prime_bonus_z2",
      "bruxelles_prime_bonus_z3",
      "bruxelles_prime_bonus_z4",
      "bruxelles_prime_bonus_z5",
      "bruxelles_prime_bonus_z6",
      "bruxelles_prime_bonus_z7",
      "bruxelles_prime_bonus_z9",
      "bruxelles_prime_bonus_z10"
    ]

    # Charger seulement les définitions des primes bonus
    load Rails.root.join("db", "seeds", "bruxelles", "bonus_primes_only.rb")

    puts "✅ Primes bonus Z1-Z10 mises à jour"
  end
end
