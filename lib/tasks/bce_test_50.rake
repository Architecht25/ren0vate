namespace :bce do
  desc "Test import avec exactement 50 entreprises de Bruxelles"
  task test_50: :environment do
    puts "🧪 TEST - Import de 50 entreprises de Bruxelles"
    puts "=" * 50
    puts ""

    # Vérification des fichiers
    required_files = %w[address.csv enterprise.csv denomination.csv activity.csv]
    base_path = Rails.root.join('db', 'bce_data')

    puts "📁 Vérification des fichiers CSV..."
    required_files.each do |file|
      file_path = base_path.join(file)
      if File.exist?(file_path)
        size_mb = File.size(file_path) / 1024.0 / 1024.0
        puts "  ✅ #{file} (#{size_mb.round(2)} MB)"
      else
        puts "  ❌ #{file} - MANQUANT"
        exit 1
      end
    end
    puts ""

    # Nettoyage préalable (optionnel)
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

    # Import
    puts "🚀 Démarrage import 50 entreprises..."
    start_time = Time.current

    service = Entreprises::BrusselsBceImportService.new
    result = service.import_brussels_sample(50)

    end_time = Time.current
    duration = end_time - start_time

    # Statistiques finales
    puts ""
    puts "=" * 50
    puts "📊 RÉSULTATS TEST 50 ENTREPRISES"
    puts "=" * 50
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

    # Taille base
    db_path = Rails.root.join('db', 'development.sqlite3')
    if File.exist?(db_path)
      db_size_mb = File.size(db_path) / 1024.0 / 1024.0
      puts "💾 Taille base: #{db_size_mb.round(2)} MB"
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
    puts "🎉 Test terminé!"
  end
end
