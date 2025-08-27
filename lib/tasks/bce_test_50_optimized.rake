namespace :bce do
  desc "Test import optimisé avec 50 entreprises de Bruxelles"
  task test_50_optimized: :environment do
    puts "🚀 TEST OPTIMISÉ - Import de 50 entreprises de Bruxelles"
    puts "=" * 60
    puts ""

    # Nettoyage préalable
    print "Vider la base avant l'import? (y/N): "
    response = $stdin.gets.chomp.downcase
    if response == 'y' || response == 'yes'
      puts "🧹 Nettoyage de la base..."
      BceEnterprise.destroy_all
      BceDenomination.destroy_all
      BceAddress.destroy_all
      BceActivity.destroy_all
      puts "✅ Base nettoyée"
    end

    # Import optimisé
    puts "🚀 Démarrage import optimisé..."
    start_time = Time.current

    service = Entreprises::BrusselsBceImportServiceOptimized.new
    result = service.import_brussels_sample_optimized(50)

    end_time = Time.current
    duration = end_time - start_time

    # Statistiques finales
    puts ""
    puts "=" * 60
    puts "📊 RÉSULTATS TEST OPTIMISÉ"
    puts "=" * 60
    puts "⏱️  Durée: #{duration.round(2)} secondes"
    puts "✅ Entreprises importées: #{result[:imported]}"
    puts "❌ Erreurs: #{result[:errors].size}" if result[:errors] && result[:errors].size > 0
    puts ""

    # Vérification en base
    total_enterprises = BceEnterprise.count
    total_addresses = BceAddress.count
    total_denominations = BceDenomination.count
    total_activities = BceActivity.count

    puts "📈 Données en base:"
    puts "  - Entreprises: #{total_enterprises}"
    puts "  - Adresses: #{total_addresses}"
    puts "  - Dénominations: #{total_denominations}"
    puts "  - Activités: #{total_activities}"
    puts ""

    # Échantillon
    if total_enterprises > 0
      puts "📋 Échantillon (3 premières entreprises):"
      BceEnterprise.includes(:bce_addresses, :bce_denominations).limit(3).each do |e|
        puts "  #{e.enterprise_number}:"
        puts "    - Adresses: #{e.bce_addresses.count}"
        puts "    - Dénominations: #{e.bce_denominations.count}"
        puts "    - Activités: #{e.bce_activities.count}"
      end
    end

    # Estimation pour 144k
    if total_enterprises > 0 && duration > 0
      rate_per_sec = total_enterprises / duration
      estimated_144k = 144_902 / rate_per_sec / 60 # en minutes
      puts ""
      puts "🔮 ESTIMATION 144k entreprises:"
      puts "   Vitesse: #{rate_per_sec.round(2)} entreprises/sec"
      puts "   Temps estimé: #{estimated_144k.round(1)} minutes"
    end

    puts ""
    puts "🎉 Test optimisé terminé!"
  end
end
