namespace :notifications do
  desc "Générer les notifications automatiques pour tous les utilisateurs"
  task generate_automatic: :environment do
    puts "🔔 Génération des notifications automatiques..."

    start_time = Time.current
    initial_count = Notification.count

    NotificationService.generate_automatic_notifications

    end_time = Time.current
    new_count = Notification.count
    generated = new_count - initial_count

    puts "✅ Terminé en #{(end_time - start_time).round(2)}s"
    puts "📊 #{generated} nouvelles notifications générées"
    puts "📈 Total notifications: #{new_count}"
  end

  desc "Nettoyer les notifications expirées"
  task cleanup_expired: :environment do
    puts "🧹 Nettoyage des notifications expirées..."

    expired_count = Notification.where('expires_at < ?', Time.current).count
    Notification.where('expires_at < ?', Time.current).destroy_all

    puts "✅ #{expired_count} notifications expirées supprimées"
  end

  desc "Marquer toutes les notifications comme lues pour un utilisateur"
  task :mark_all_read, [:user_id] => :environment do |t, args|
    if args[:user_id].blank?
      puts "❌ Usage: rake notifications:mark_all_read[USER_ID]"
      exit 1
    end

    user = User.find(args[:user_id])
    count = user.unread_notifications_count
    user.mark_all_notifications_as_read!

    puts "✅ #{count} notifications marquées comme lues pour #{user.email}"
  end

  desc "Envoyer une notification admin à tous les utilisateurs"
  task :send_admin, [:type, :title, :message] => :environment do |t, args|
    if args[:type].blank? || args[:title].blank? || args[:message].blank?
      puts "❌ Usage: rake notifications:send_admin[TYPE,TITLE,MESSAGE]"
      puts "Types disponibles: admin_info, admin_legal, admin_maintenance, admin_nouvelle_prime, admin_urgent"
      exit 1
    end

    type = args[:type].to_sym
    unless Notification.types.key?(type.to_s)
      puts "❌ Type invalide. Types disponibles: #{Notification.types.keys.join(', ')}"
      exit 1
    end

    user_count = User.count
    Notification.create_admin_notification(
      type: type,
      title: args[:title],
      message: args[:message]
    )

    puts "✅ Notification admin envoyée à #{user_count} utilisateurs"
    puts "📧 Type: #{type}"
    puts "📧 Titre: #{args[:title]}"
  end

  desc "Statistiques des notifications"
  task stats: :environment do
    puts "📊 STATISTIQUES DES NOTIFICATIONS"
    puts "=" * 40

    total = Notification.count
    unread = Notification.unread.count
    active = Notification.active.count
    expired = Notification.where('expires_at < ?', Time.current).count

    puts "Total: #{total}"
    puts "Non lues: #{unread}"
    puts "Actives: #{active}"
    puts "Expirées: #{expired}"
    puts ""

    puts "Par type:"
    Notification.group(:type).count.each do |type, count|
      puts "  #{type}: #{count}"
    end
    puts ""

    puts "Par priorité:"
    Notification.group(:priority).count.each do |priority, count|
      puts "  #{priority || 'non définie'}: #{count}"
    end
    puts ""

    puts "Utilisateurs avec notifications non lues:"
    users_with_unread = User.joins(:notifications)
                           .where(notifications: { read_at: nil })
                           .distinct
                           .count
    puts "  #{users_with_unread} utilisateurs"
  end

  desc "Tâche de maintenance quotidienne"
  task daily_maintenance: :environment do
    puts "🔄 Maintenance quotidienne des notifications..."

    # Générer les nouvelles notifications
    Rake::Task["notifications:generate_automatic"].invoke

    # Nettoyer les expirées
    Rake::Task["notifications:cleanup_expired"].invoke

    puts "✅ Maintenance quotidienne terminée"
  end
end
