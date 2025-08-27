namespace :admin do
  desc "Promote a user to admin role"
  task :promote, [:email] => :environment do |t, args|
    email = args[:email]

    if email.blank?
      puts "Usage: rails admin:promote[user@example.com]"
      exit
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "❌ Utilisateur avec l'email '#{email}' non trouvé."
      exit
    end

    if user.admin?
      puts "✅ L'utilisateur #{email} est déjà administrateur."
    else
      user.update!(role: 'admin')
      puts "🚀 L'utilisateur #{email} a été promu administrateur avec succès!"
    end
  end

  desc "List all admins"
  task :list => :environment do
    admins = User.admin

    if admins.empty?
      puts "❌ Aucun administrateur trouvé."
    else
      puts "👥 Administrateurs actuels:"
      admins.each do |admin|
        puts "  - #{admin.email} (#{admin.first_name} #{admin.last_name})"
      end
    end
  end

  desc "Create first admin user"
  task :create_first => :environment do
    puts "🚀 Création du premier administrateur..."

    print "Email: "
    email = STDIN.gets.chomp

    print "Mot de passe: "
    password = STDIN.gets.chomp

    print "Prénom: "
    first_name = STDIN.gets.chomp

    print "Nom: "
    last_name = STDIN.gets.chomp

    user = User.new(
      email: email,
      password: password,
      password_confirmation: password,
      first_name: first_name,
      last_name: last_name,
      role: 'admin',
      confirmed_at: Time.current # Confirmer automatiquement
    )

    if user.save
      puts "✅ Administrateur créé avec succès!"
      puts "📧 Email: #{user.email}"
      puts "👤 Nom: #{user.first_name} #{user.last_name}"
      puts "🔑 Rôle: #{user.role}"
    else
      puts "❌ Erreur lors de la création:"
      user.errors.full_messages.each { |msg| puts "  - #{msg}" }
    end
  end

  desc "Reset user password"
  task :reset_password, [:email] => :environment do |t, args|
    email = args[:email]

    if email.blank?
      puts "Usage: rails admin:reset_password[user@example.com]"
      exit
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "❌ Utilisateur avec l'email '#{email}' non trouvé."
      exit
    end

    print "Nouveau mot de passe: "
    new_password = STDIN.gets.chomp

    if new_password.length < 6
      puts "❌ Le mot de passe doit faire au moins 6 caractères."
      exit
    end

    user.password = new_password
    user.password_confirmation = new_password

    if user.save
      puts "✅ Mot de passe modifié avec succès pour #{email}!"
    else
      puts "❌ Erreur lors de la modification:"
      user.errors.full_messages.each { |msg| puts "  - #{msg}" }
    end
  end

  desc "Quick password reset for robin@primes-services.be"
  task :reset_robin => :environment do
    user = User.find_by(email: 'robin@primes-services.be')

    if user.nil?
      puts "❌ Utilisateur robin@primes-services.be non trouvé."
      exit
    end

    # Mot de passe temporaire
    temp_password = "renovate2025"

    user.password = temp_password
    user.password_confirmation = temp_password

    if user.save
      puts "✅ Mot de passe réinitialisé pour robin@primes-services.be!"
      puts "🔑 Nouveau mot de passe temporaire: #{temp_password}"
      puts "⚠️  Pensez à le changer après connexion!"
    else
      puts "❌ Erreur lors de la modification:"
      user.errors.full_messages.each { |msg| puts "  - #{msg}" }
    end
  end
end
