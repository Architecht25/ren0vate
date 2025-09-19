# =====================================================
# PRIMES BRUXELLES RENOLUTION - VERSION MODULAIRE
# =====================================================
# Refactorisation du fichier monolithique (2028 lignes)
# en modules organisés par type de prime (A-Z)
# =====================================================

puts "🏗️ Chargement des primes Bruxelles RENOLUTION (version modulaire)..."

# Vérification de la région Bruxelles
unless Category.where(region: "bruxelles").exists?
  puts "❌ ERREUR: Les catégories Bruxelles doivent être créées avant les primes"
  return
end

# Chargement des modules de primes par ordre alphabétique
load Rails.root.join("db", "seeds", "bruxelles", "primes", "prime_a_services_etudes.rb")
load Rails.root.join("db", "seeds", "bruxelles", "primes", "prime_b_installations_chantier.rb")
load Rails.root.join("db", "seeds", "bruxelles", "primes", "prime_c_gros_oeuvre.rb")
load Rails.root.join("db", "seeds", "bruxelles", "primes", "prime_d_salubrite.rb")
load Rails.root.join("db", "seeds", "bruxelles", "primes", "prime_e_toiture.rb")
load Rails.root.join("db", "seeds", "bruxelles", "primes", "prime_f_facades.rb")
load Rails.root.join("db", "seeds", "bruxelles", "primes", "prime_g_portes_fenetres.rb")
load Rails.root.join("db", "seeds", "bruxelles", "primes", "prime_h_sols.rb")
load Rails.root.join("db", "seeds", "bruxelles", "primes", "prime_i_amenagement.rb")
load Rails.root.join("db", "seeds", "bruxelles", "primes", "prime_j_chauffage.rb")
load Rails.root.join("db", "seeds", "bruxelles", "primes", "prime_klmz_finales.rb")

puts "✅ Toutes les primes Bruxelles RENOLUTION ont été chargées avec succès!"
puts "📊 Structure modulaire:"
puts "   🎯 Prime A: Services & études (8 primes)"
puts "   🏗️ Prime B: Installations de chantier (1 prime)"
puts "   🏘️ Prime C: Gros-œuvre & gestion eau (4 primes)"
puts "   🏠 Prime D: Salubrité (2 primes)"
puts "   🏘️ Prime E: Toiture (5 primes)"
puts "   🏢 Prime F: Façades (6 primes)"
puts "   🚪 Prime G: Portes & fenêtres (4 primes)"
puts "   🏢 Prime H: Sols & planchers (2 primes)"
puts "   🏠 Prime I: Aménagement intérieur (4 primes)"
puts "   🔥 Prime J: Chauffage & chauffe-eau (7 primes)"
puts "   🚿 Prime K: Sanitaires (1 prime)"
puts "   ⚡ Prime L: Électricité & gaz (1 prime)"
puts "   💨 Prime M: Ventilation (2 primes)"
puts "   🎁 Prime Z: Bonus (1 prime)"
puts ""
puts "🎯 Total: ~48 primes Bruxelles RENOLUTION organisées en 11 modules"
puts "📈 Réduction: 2028 lignes → ~35 lignes (fichier principal)"
puts "🔧 Maintenabilité: Chaque type de prime dans son propre fichier"
