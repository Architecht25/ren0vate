namespace :production do
  desc "Assure que Robin soit admin en production"
  task ensure_admin: :environment do
    puts "🔍 Vérification des droits d'administrateur en production..."

    # Votre email principal
    admin_email = "robin@primes-services.be"

    # Chercher l'utilisateur
    user = User.find_by(email: admin_email)

    if user.nil?
      puts "❌ ERREUR: Utilisateur #{admin_email} non trouvé!"
      puts "   Créez d'abord un compte avec cet email"
      exit 1
    end

    # Vérifier s'il est déjà admin
    if user.admin?
      puts "✅ #{admin_email} est déjà administrateur"
      puts "   Rôle actuel: #{user.display_role}"
    else
      puts "⚠️  #{admin_email} n'est pas admin, promotion en cours..."
      user.update!(role: :admin)
      puts "✅ #{admin_email} promu administrateur avec succès!"
      puts "   Nouveau rôle: #{user.display_role}"
    end

    # Affichage récapitulatif de tous les rôles
    puts "\n📊 Récapitulatif des rôles utilisateurs:"
    User.all.each do |u|
      role_badge = case u.role
      when 'admin' then '👑'
      when 'moderator' then '🛡️'
      else '👤'
      end
      puts "   #{role_badge} #{u.email}: #{u.display_role}"
    end

    puts "\n🚀 Système prêt pour la production!"
  end

  desc "Affiche tous les utilisateurs et leurs rôles"
  task show_roles: :environment do
    puts "📊 Liste complète des utilisateurs et rôles:"
    puts "=" * 50

    User.all.order(:created_at).each_with_index do |user, index|
      role_badge = case user.role
      when 'admin' then '👑 ADMIN'
      when 'moderator' then '🛡️ MODERATOR'
      else '👤 USER'
      end

      puts "#{index + 1}. #{user.email}"
      puts "   Rôle: #{role_badge}"
      puts "   Créé: #{user.created_at.strftime('%d/%m/%Y à %H:%M')}"
      puts "   Confirmé: #{user.confirmed? ? '✅' : '❌'}"
      puts "-" * 30
    end

    puts "\nStatistiques:"
    puts "- Total utilisateurs: #{User.count}"
    puts "- Administrateurs: #{User.admin.count}"
    puts "- Modérateurs: #{User.moderator.count}"
    puts "- Utilisateurs standard: #{User.user.count}"
  end
end
