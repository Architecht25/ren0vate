namespace :bce do
  desc "Import BCE data from CSV files"
  task import: :environment do
    puts "🚀 Début de l'import des données BCE..."

    start_time = Time.current
    results = FastBceImportService.import_all
    end_time = Time.current

    duration = (end_time - start_time).round(2)

    puts "\n📊 Résultats de l'import:"
    puts "   - Entreprises: #{results[:enterprises]}"
    puts "   - Dénominations: #{results[:denominations]}"
    puts "   - Adresses: #{results[:addresses]}"
    puts "   - Activités: #{results[:activities]}"
    puts "   - Durée: #{duration} secondes"

    if results[:errors].any?
      puts "\n❌ Erreurs rencontrées:"
      results[:errors].each { |error| puts "   - #{error}" }
    else
      puts "\n✅ Import terminé avec succès!"
    end
  end

  desc "Download and extract BCE data"
  task download: :environment do
    puts "📥 Téléchargement des données BCE..."

    # Créer le dossier de données
    data_dir = Rails.root.join('db', 'bce_data')
    FileUtils.mkdir_p(data_dir)

    # URL officielle BCE
    url = "https://statbel.fgov.be/sites/default/files/files/opendata/BCED/KboOpenData_0138_2025_08_Full.zip"
    zip_path = data_dir.join('KboOpenData_0138_2025_08_Full.zip')

    puts "📄 Téléchargement de: #{url}"
    puts "📁 Destination: #{zip_path}"

    # Note: Téléchargement manuel requis car le fichier fait 309MB
    puts "\n⚠️  Le fichier fait 309MB. Téléchargement manuel recommandé:"
    puts "   1. Visitez: #{url}"
    puts "   2. Sauvegardez vers: #{zip_path}"
    puts "   3. Lancez: rails bce:extract"

    puts "\n💡 Ou utilisez wget/curl:"
    puts "   cd #{data_dir}"
    puts "   wget #{url}"
  end

  desc "Extract BCE zip file"
  task extract: :environment do
    puts "📦 Extraction des données BCE..."

    data_dir = Rails.root.join('db', 'bce_data')
    zip_path = data_dir.join('KboOpenData_0138_2025_08_Full.zip')

    unless File.exist?(zip_path)
      puts "❌ Fichier ZIP non trouvé: #{zip_path}"
      puts "   Lancez d'abord: rails bce:download"
      exit 1
    end

    puts "📁 Extraction de: #{zip_path}"
    puts "📁 Vers: #{data_dir}"

    require 'zip'

    Zip::File.open(zip_path) do |zip_file|
      zip_file.each do |entry|
        # Extraire seulement les fichiers CSV nécessaires
        if entry.name.match?(/\.(csv)$/i)
          puts "   📄 #{entry.name}"
          entry.extract(data_dir.join(entry.name)) { true }
        end
      end
    end

    puts "✅ Extraction terminée!"
    puts "\n📊 Fichiers extraits:"
    Dir[data_dir.join('*.csv')].each do |file|
      size = File.size(file) / 1024 / 1024
      puts "   - #{File.basename(file)} (#{size}MB)"
    end

    puts "\n🚀 Prêt pour l'import. Lancez: rails bce:import"
  end

  desc "Reset BCE database tables"
  task reset: :environment do
    puts "🗑️  Nettoyage des tables BCE..."

    BceActivity.delete_all
    BceAddress.delete_all
    BceDenomination.delete_all
    BceEnterprise.delete_all

    puts "✅ Tables nettoyées!"
  end

  desc "Show BCE statistics"
  task stats: :environment do
    puts "📊 Statistiques BCE:"
    puts "   - Entreprises: #{BceEnterprise.count}"
    puts "   - Dénominations: #{BceDenomination.count}"
    puts "   - Adresses: #{BceAddress.count}"
    puts "   - Activités: #{BceActivity.count}"

    if BceEnterprise.any?
      puts "\n📈 Entreprises par statut:"
      BceEnterprise.group(:status_code).count.each do |status, count|
        puts "   - #{status}: #{count}"
      end
    end
  end

  desc "Test search functionality"
  task test_search: :environment do
    test_number = "0833618097"
    puts "🔍 Test de recherche pour: #{test_number}"

    result = BceOnDemandService.search_enterprise(test_number)

    if result[:success]
      puts "✅ Entreprise trouvée:"
      result[:data].each { |k, v| puts "   #{k}: #{v}" }

      # Test dénomination
      denomination = BceOnDemandService.search_denomination(test_number)
      if denomination
        puts "\n📝 Dénomination: #{denomination[:denomination]}"
      end

      # Test adresses
      addresses = BceOnDemandService.search_addresses(test_number)
      puts "\n🏠 Adresses trouvées: #{addresses.size}"

      # Test activités
      activities = BceOnDemandService.search_activities(test_number)
      puts "🏢 Activités trouvées: #{activities.size}"
    else
      puts "❌ #{result[:error]}"
    end
  end
end
