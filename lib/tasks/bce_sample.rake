namespace :bce do
  desc "Import échantillon d'entreprises de Bruxelles (safe pour GitHub)"
  task import_brussels_sample: :environment do
    sample_size = ENV['SAMPLE_SIZE']&.to_i || 50

    puts "🇧🇪 Import échantillon Bruxelles - #{sample_size} entreprises max"
    puts "💾 Cible: < 50 MB pour compatibilité GitHub"
    puts ""

    # Vérification des fichiers
    required_files = %w[address.csv enterprise.csv denomination.csv activity.csv]
    missing_files = required_files.reject do |file|
      File.exist?(Rails.root.join('db', 'bce_data', file))
    end

    if missing_files.any?
      puts "❌ Fichiers manquants: #{missing_files.join(', ')}"
      exit 1
    end

    # Confirmation
    print "Continuer avec l'import de #{sample_size} entreprises? (y/N): "
    response = $stdin.gets.chomp.downcase
    unless response == 'y' || response == 'yes'
      puts "❌ Import annulé"
      exit 0
    end

    service = Entreprises::BrusselsBceImportService.new
    result = service.import_brussels_sample(sample_size)

    # Vérification taille
    db_size_mb = File.size(Rails.root.join('db', 'development.sqlite3')) / 1024.0 / 1024.0

    puts ""
    puts "=" * 60
    puts "📊 RÉSULTATS IMPORT ÉCHANTILLON"
    puts "=" * 60
    puts "✅ Entreprises importées: #{result[:imported]}"
    puts "💾 Taille base de données: #{db_size_mb.round(2)} MB"
    puts "✅ Compatible GitHub: #{db_size_mb < 50 ? 'OUI' : 'NON ⚠️'}"
    puts ""

    if db_size_mb >= 50
      puts "⚠️  Base > 50 MB - risque GitHub. Réduisez SAMPLE_SIZE"
    else
      puts "🎉 Import terminé - prêt pour commit GitHub!"
    end
  end
end
