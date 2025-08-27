namespace :users do
  desc "Recréer tous les utilisateurs de production avec leurs données"
  task recreate_production: :environment do
    puts "🚨 RECONSTRUCTION UTILISATEURS PRODUCTION"
    puts "=" * 50
    puts ""

    # Confirmation
    if Rails.env.production?
      print "⚠️  ATTENTION: Vous êtes en PRODUCTION! Continuer? (yes/NO): "
      response = $stdin.gets.chomp.downcase
      unless response == 'yes'
        puts "❌ Opération annulée"
        exit 0
      end
    end

    puts "🔄 Chargement du seed utilisateurs..."
    load Rails.root.join("db", "seeds", "users_production.rb")

    puts ""
    puts "🎉 Reconstruction terminée!"
    puts "📱 Vous pouvez maintenant vous connecter avec:"
    puts "   📧 robin@primes-services.be"
    puts "   🔐 robin123456"
  end

  desc "Créer seulement l'admin principal"
  task create_admin_only: :environment do
    puts "👑 Création admin principal..."

    admin = User.create!(
      email: 'robin@primes-services.be',
      password: 'robin123456',
      password_confirmation: 'robin123456',
      first_name: 'Robin',
      last_name: 'Admin',
      role: 'admin',
      phone: '+32 2 123 45 67',
      city: 'Bruxelles',
      postal_code: '1000',
      confirmed_at: Time.current
    )

    puts "✅ Admin créé: #{admin.email}"
    puts "🔐 Mot de passe: robin123456"
  end

  desc "Compter les utilisateurs actuels"
  task count: :environment do
    puts "📊 Statistiques utilisateurs:"
    puts "  Total: #{User.count}"
    puts "  Admins: #{User.where(role: 'admin').count}"
    puts "  Utilisateurs: #{User.where(role: 'user').count}"

    if User.count > 0
      puts ""
      puts "📋 Liste:"
      User.all.each do |u|
        puts "  - #{u.email} (#{u.role})"
      end
    end
  end
end
