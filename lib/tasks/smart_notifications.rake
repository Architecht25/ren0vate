namespace :notifications do
  desc "Générer des notifications intelligentes basées sur les données utilisateurs"
  task generate_smart: :environment do
    puts "🤖 Démarrage de la génération de notifications intelligentes..."
    puts Time.current.strftime("Exécuté le %d/%m/%Y à %H:%M")
    puts "=" * 60

    results = SmartNotificationGeneratorService.generate_all

    puts "\n📈 RAPPORT D'EXÉCUTION:"
    puts "=" * 30

    total_generated = results.values.sum

    puts "✅ #{total_generated} nouvelles notifications générées"
    puts "📊 Répartition par catégorie:"
    results.each do |category, count|
      next if count.zero?
      category_name = case category
      when :profile_completion then "📝 Complétion profils"
      when :property_setup then "🏠 Configuration propriétés"
      when :simulation_encouragement then "💰 Encouragement simulations"
      when :geocoding_issues then "📍 Problèmes géocodage"
      when :admin_insights then "👨‍💼 Insights administratifs"
      when :engagement then "🔄 Réengagement utilisateurs"
      end
      puts "   #{category_name}: #{count}"
    end

    puts "\n📋 Statistiques globales:"
    puts "   Total notifications dans le système: #{Notification.count}"
    puts "   Notifications non lues: #{Notification.unread.count}"
    puts "   Utilisateurs avec notifications: #{User.joins(:notifications).distinct.count}"

    # Notifications par priorité
    puts "\n🎯 Répartition par priorité:"
    Notification.group(:priority).count.each do |priority, count|
      icon = case priority
      when 'critique' then '🔴'
      when 'haute' then '🟠'
      when 'normale' then '🟢'
      else '⚪'
      end
      puts "   #{icon} #{priority.capitalize}: #{count}"
    end

    puts "\n✅ Génération terminée avec succès!"
    puts Time.current.strftime("Terminé le %d/%m/%Y à %H:%M")
  end

  desc "Nettoyer les anciennes notifications expirées"
  task cleanup_expired: :environment do
    puts "🧹 Nettoyage des notifications expirées..."

    expired_count = Notification.where('expires_at < ?', Time.current).count

    if expired_count > 0
      Notification.where('expires_at < ?', Time.current).destroy_all
      puts "✅ #{expired_count} notifications expirées supprimées"
    else
      puts "ℹ️  Aucune notification expirée à nettoyer"
    end
  end

  desc "Statistiques détaillées des notifications"
  task stats: :environment do
    puts "📊 STATISTIQUES DÉTAILLÉES DES NOTIFICATIONS"
    puts "=" * 50

    total = Notification.count
    puts "📈 Vue d'ensemble:"
    puts "   Total notifications: #{total}"
    puts "   Non lues: #{Notification.unread.count} (#{(Notification.unread.count.to_f / total * 100).round(1)}%)"
    puts "   Lues: #{Notification.read_notifications.count}"
    puts "   Expirées: #{Notification.where('expires_at < ?', Time.current).count}"

    puts "\n📋 Par type:"
    Notification.group(:type).order('count_all DESC').count.each do |type, count|
      percentage = (count.to_f / total * 100).round(1)
      puts "   #{type}: #{count} (#{percentage}%)"
    end

    puts "\n🎯 Par priorité:"
    Notification.group(:priority).count.each do |priority, count|
      percentage = (count.to_f / total * 100).round(1)
      puts "   #{priority.capitalize}: #{count} (#{percentage}%)"
    end

    puts "\n📊 Par catégorie:"
    Notification.group(:category).count.each do |category, count|
      percentage = (count.to_f / total * 100).round(1)
      puts "   #{category.capitalize}: #{count} (#{percentage}%)"
    end

    puts "\n👥 Top 5 utilisateurs avec le plus de notifications:"
    User.joins(:notifications)
        .group('users.email')
        .order('count_notifications_id DESC')
        .limit(5)
        .count('notifications.id')
        .each_with_index do |(email, count), index|
      puts "   #{index + 1}. #{email}: #{count} notifications"
    end

    puts "\n📅 Activité récente:"
    puts "   Aujourd'hui: #{Notification.where('created_at > ?', Date.current).count}"
    puts "   Cette semaine: #{Notification.where('created_at > ?', 1.week.ago).count}"
    puts "   Ce mois: #{Notification.where('created_at > ?', 1.month.ago).count}"
  end

  desc "Envoyer un résumé des notifications aux admins"
  task admin_summary: :environment do
    puts "📧 Génération du résumé admin des notifications..."

    admin_users = User.admin

    if admin_users.empty?
      puts "⚠️  Aucun administrateur trouvé"
      exit
    end

    # Statistiques pour le résumé
    unread_count = Notification.unread.count
    high_priority_count = Notification.where(priority: ['haute', 'critique']).unread.count
    recent_count = Notification.where('created_at > ?', 24.hours.ago).count

    admin_users.each do |admin|
      # Créer une notification de résumé pour l'admin
      unless admin.notifications.where(
        type: 'admin_info',
        created_at: 1.day.ago..Time.current
      ).where("title LIKE ?", "%Résumé%").exists?

        Notification.create!(
          user: admin,
          type: 'admin_info',
          category: 'systeme',
          priority: 'normale',
          title: '📊 Résumé quotidien des notifications',
          message: "Rapport du #{Date.current.strftime('%d/%m/%Y')} : #{unread_count} notifications non lues, #{high_priority_count} prioritaires, #{recent_count} créées en 24h. #{User.joins(:notifications).distinct.count} utilisateurs ont des notifications actives.",
          action_url: '/admin/dashboard'
        )

        puts "✅ Résumé envoyé à #{admin.email}"
      end
    end
  end

  desc "Tâche complète : génération + nettoyage + résumé admin"
  task daily_maintenance: [:generate_smart, :cleanup_expired, :admin_summary] do
    puts "\n🎉 Maintenance quotidienne des notifications terminée!"
  end
end
