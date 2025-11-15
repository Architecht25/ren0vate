namespace :cleanup do
  desc "Nettoyer les comptes de test en développement"
  task test_users: :environment do
    puts "🧹 Nettoyage des comptes de test..."

    # Liste des emails de test à supprimer
    test_emails = [
      "test_no_confirm_1763046032@example.com",
      "test1763045828@example.com",
      "test11@example.com",
      "test10@example.com",
      "test9@example.com",
      "test8@example.com",
      "test7@example.com",
      "test6@example.com",
      "test5@example.com",
      "test4@example.com",
      "test2@example.com",
      "test@example.com",
      "user2@test.com",
      "user1@test.com"
    ]

    # Garder admin@test.com car c'est l'admin principal
    admin_email = "admin@test.com"

    deleted_count = 0
    kept_users = []

    test_emails.each do |email|
      user = User.find_by(email: email)
      if user
        if user.admin? && User.admin.count == 1
          puts "⚠️  Conservation de #{email} (dernier administrateur)"
          kept_users << email
        else
          puts "🗑️  Suppression de #{email}..."

          # Supprimer les données liées en cascade
          properties_count = user.properties.count
          documents_count = user.documents.count
          notifications_count = user.notifications.count

          user.destroy!
          deleted_count += 1

          puts "   ✅ Supprimé avec #{properties_count} propriétés, #{documents_count} documents, #{notifications_count} notifications"
        end
      else
        puts "⚪ #{email} - Utilisateur non trouvé (déjà supprimé?)"
      end
    end

    puts "\n📊 Résumé du nettoyage:"
    puts "   🗑️  #{deleted_count} comptes de test supprimés"
    puts "   ✅ #{kept_users.count} comptes conservés: #{kept_users.join(', ')}" if kept_users.any?

    remaining_users = User.count
    admin_count = User.admin.count

    puts "   👥 #{remaining_users} utilisateurs restants (dont #{admin_count} admin(s))"
    puts "\n🎉 Nettoyage terminé!"
  end

  desc "Nettoyer TOUS les comptes de test (DANGER - garder seulement admin)"
  task all_test_users: :environment do
    puts "⚠️  ATTENTION: Nettoyage complet des comptes de test"
    puts "   Cette action va supprimer TOUS les comptes sauf les administrateurs"

    if Rails.env.production?
      puts "❌ ERREUR: Cette tâche ne peut pas être exécutée en production!"
      exit 1
    end

    # Garder seulement les administrateurs
    admin_users = User.admin
    test_users = User.user # Tous les utilisateurs non-admin

    puts "\n📋 Analyse:"
    puts "   👑 #{admin_users.count} administrateur(s) à conserver"
    puts "   🗑️  #{test_users.count} utilisateur(s) de test à supprimer"

    deleted_count = 0

    test_users.find_each do |user|
      email = user.email
      properties_count = user.properties.count
      documents_count = user.documents.count

      user.destroy!
      deleted_count += 1

      puts "🗑️  #{email} supprimé (#{properties_count} propriétés, #{documents_count} documents)"
    end

    puts "\n🎉 Nettoyage complet terminé!"
    puts "   🗑️  #{deleted_count} comptes supprimés"
    puts "   👑 #{User.admin.count} administrateur(s) conservé(s)"
    puts "   👥 #{User.count} utilisateurs total restants"
  end

  desc "Afficher un aperçu des comptes de test"
  task preview_test_users: :environment do
    puts "👀 Aperçu des comptes de test:"
    puts "\n📋 Administrateurs (conservés):"
    User.admin.each do |admin|
      puts "   👑 #{admin.email} - #{admin.created_at.strftime('%d/%m/%Y')}"
    end

    puts "\n📋 Utilisateurs de test (à supprimer):"
    test_pattern = /@(example\.com|test\.com)$/
    User.user.where("email ~* ?", test_pattern.source).each do |user|
      puts "   🗑️  #{user.email} - #{user.properties.count} propriétés, #{user.documents.count} documents"
    end

    puts "\n📊 Résumé:"
    puts "   👑 #{User.admin.count} administrateur(s)"
    puts "   🗑️  #{User.user.where("email ~* ?", test_pattern.source).count} compte(s) de test"
    puts "   👥 #{User.count} total utilisateurs"
  end
end
