namespace :documents do
  desc "Supprimer toutes les factures d'un utilisateur spécifique"
  task :delete_user_factures, [:user_id] => :environment do |t, args|
    user_id = args[:user_id] || ENV['USER_ID']

    unless user_id
      puts "❌ Erreur: Veuillez spécifier un USER_ID"
      puts "Usage: rake documents:delete_user_factures[USER_ID]"
      puts "   ou: USER_ID=286 rake documents:delete_user_factures"
      exit
    end

    user = User.find_by(id: user_id)

    unless user
      puts "❌ Utilisateur #{user_id} introuvable"
      exit
    end

    factures = user.documents.where(type_document: 'facture')
    count = factures.count

    puts "👤 Utilisateur: #{user.email} (ID: #{user.id})"
    puts "📄 Nombre de factures à supprimer: #{count}"

    if count == 0
      puts "✅ Aucune facture à supprimer"
      exit
    end

    puts "\n⚠️  ATTENTION: Cette action est irréversible!"
    puts "Suppression en cours..."

    deleted_count = 0
    factures.find_each do |facture|
      begin
        facture.destroy
        deleted_count += 1
        print "\r🗑️  Supprimé: #{deleted_count}/#{count}"
      rescue => e
        puts "\n❌ Erreur lors de la suppression du document #{facture.id}: #{e.message}"
      end
    end

    puts "\n✅ Suppression terminée!"
    puts "📊 Total supprimé: #{deleted_count} factures"

    # Vérification
    remaining = user.documents.where(type_document: 'facture').count
    puts "📋 Factures restantes: #{remaining}"
  end
end
