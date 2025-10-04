namespace :db do
  namespace :cleanup do
    desc "Supprimer les comptes utilisateurs spécifiques de la production"
    task remove_unwanted_users: :environment do
      puts "🧹 Début de la suppression des comptes utilisateurs indésirables..."

      # Liste des emails à supprimer
      emails_to_remove = [
        'info@primes-services.be',
        'florence@primes-services.be',
        'clemence@primes-services.be',
        'jana@primes-services.be',
        'marie@primes-services.be'
      ]

      # Statistiques avant suppression
      total_users_before = User.count
      puts "📊 Nombre total d'utilisateurs avant suppression: #{total_users_before}"

      deleted_count = 0
      not_found_count = 0

      emails_to_remove.each do |email|
        user = User.find_by(email: email)

        if user
          # Afficher les informations de l'utilisateur avant suppression
          puts "🔍 Utilisateur trouvé: #{user.email} - #{user.first_name} #{user.last_name}"

          # Compter les propriétés et projets associés
          properties_count = user.properties.count
          projects_count = user.projects.count

          puts "  📋 Propriétés associées: #{properties_count}"
          puts "  🔧 Projets associés: #{projects_count}"

          begin
            # Supprimer l'utilisateur (cascade delete devrait supprimer propriétés et projets)
            user.destroy!
            puts "  ✅ Utilisateur #{email} supprimé avec succès"
            deleted_count += 1
          rescue => e
            puts "  ❌ Erreur lors de la suppression de #{email}: #{e.message}"
          end
        else
          puts "⚠️  Utilisateur #{email} non trouvé dans la base de données"
          not_found_count += 1
        end

        puts "" # Ligne vide pour la lisibilité
      end

      # Statistiques finales
      total_users_after = User.count
      puts "📊 Résultats de la suppression:"
      puts "  👥 Utilisateurs avant: #{total_users_before}"
      puts "  👥 Utilisateurs après: #{total_users_after}"
      puts "  ✅ Supprimés avec succès: #{deleted_count}"
      puts "  ⚠️  Non trouvés: #{not_found_count}"
      puts "  🏠 Propriétés restantes: #{Property.count}"
      puts "  🔧 Projets restants: #{Project.count}"

      if deleted_count > 0
        puts ""
        puts "🎉 Suppression terminée! #{deleted_count} compte(s) supprimé(s) de la base de données."
      else
        puts ""
        puts "ℹ️  Aucun compte n'a été supprimé."
      end
    end

    desc "Lister les utilisateurs qui seraient supprimés (mode dry-run)"
    task preview_user_removal: :environment do
      puts "👀 Aperçu des utilisateurs qui seraient supprimés..."

      emails_to_remove = [
        'info@primes-services.be',
        'florence@primes-services.be',
        'clemence@primes-services.be',
        'jana@primes-services.be',
        'marie@primes-services.be'
      ]

      found_count = 0

      emails_to_remove.each do |email|
        user = User.find_by(email: email)

        if user
          found_count += 1
          puts "🔍 #{email} - #{user.first_name} #{user.last_name}"
          puts "    Role: #{user.role}"
          puts "    Propriétés: #{user.properties.count}"
          puts "    Projets: #{user.projects.count}"
          puts "    Créé le: #{user.created_at&.strftime('%d/%m/%Y à %H:%M')}"
          puts ""
        else
          puts "⚠️  #{email} - NON TROUVÉ"
        end
      end

      puts "📊 Total: #{found_count} utilisateur(s) trouvé(s) sur #{emails_to_remove.size}"
      puts ""
      puts "Pour procéder à la suppression, lancez:"
      puts "  rails db:cleanup:remove_unwanted_users"
    end
  end
end
