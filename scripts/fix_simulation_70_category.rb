#!/usr/bin/env ruby

# Script pour corriger la catégorie de la simulation 70
# Le problème : elle utilise "R2" au lieu d'une catégorie de revenus valide (1,2,3,4)

require_relative '../config/environment'

puts "🔍 Correction de la catégorie pour la simulation 70..."

begin
  sim = Simulation.find(70)

  puts "📊 État actuel de la simulation 70:"
  puts "  - ID: #{sim.id}"
  puts "  - Total simulé: #{sim.total_simule}€"
  puts "  - Région: #{sim.region}"
  puts "  - Catégorie actuelle: #{sim.categorie}"
  puts "  - Category: #{sim.category}"
  puts "  - Tous les attributs: #{sim.attributes.keys.join(', ')}"

  # Corriger la catégorie de "R2" vers "2" (catégorie de revenus moyens)
  if sim.categorie == "R2"
    puts "\n🔧 Correction: R2 → 2"
    sim.update!(categorie: "2")
    puts "✅ Catégorie corrigée avec succès!"
  else
    puts "\n⚠️ Catégorie actuelle: #{sim.categorie} (pas R2)"
  end

  # Vérifier la structure des paramètres
  puts "\n📋 Paramètres actuels:"
  if sim.parameters.present?
    params = JSON.parse(sim.parameters)
    puts "  - Type de données: #{params.class}"
    puts "  - Clés principales: #{params.keys.join(', ')}" if params.is_a?(Hash)

    if params['prime_cards'].present?
      puts "  - Prime cards trouvées: #{params['prime_cards'].size} entrées"
      params['prime_cards'].each do |slug, value|
        puts "    * #{slug}: #{value}"
      end
    else
      puts "  - Aucune prime_cards trouvée"
    end
  else
    puts "  - Aucun paramètre sauvegardé"
  end

  puts "\n🎯 Simulation 70 après correction:"
  sim.reload
  puts "  - Catégorie: #{sim.categorie}"
  puts "  - Total: #{sim.total_simule}€"

rescue => e
  puts "❌ Erreur: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n✅ Script terminé!"
