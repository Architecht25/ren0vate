namespace :db do
  namespace :users do
    desc "Ajouter Michael LAES comme nouvel utilisateur réel en production"
    task add_michael_laes: :environment do
      puts "👤 Ajout de Michael LAES en production..."

      email = 'laes.michael@gmail.com'

      # Vérifier si l'utilisateur existe déjà
      existing_user = User.find_by(email: email)

      if existing_user
        puts "⚠️  L'utilisateur #{email} existe déjà dans la base de données"
        puts "   Nom: #{existing_user.first_name} #{existing_user.last_name}"
        puts "   Créé le: #{existing_user.created_at&.strftime('%d/%m/%Y à %H:%M')}"
        puts "   Propriétés: #{existing_user.properties.count}"
        puts "   Projets: #{existing_user.projects.count}"
        return
      end

      # Créer le nouvel utilisateur
      begin
        user = User.create!(
          email: 'laes.michael@gmail.com',
          password: 'Michael2025!Secure',
          password_confirmation: 'Michael2025!Secure',
          first_name: 'MICHAEL',
          last_name: 'LAES',
          role: 'user',
          phone: '+32476794725',
          city: 'OVERIJSE',
          postal_code: '3090',
          confirmed_at: Time.current
        )

        puts "✅ Utilisateur Michael LAES créé avec succès!"
        puts "   📧 Email: #{user.email}"
        puts "   👤 Nom: #{user.first_name} #{user.last_name}"
        puts "   📱 Téléphone: #{user.phone}"
        puts "   🏙️  Ville: #{user.city} (#{user.postal_code})"
        puts "   🔑 Mot de passe: Michael2025!Secure"
        puts ""
        puts "🎉 L'utilisateur peut maintenant se connecter avec ses identifiants"

      rescue => e
        puts "❌ Erreur lors de la création de l'utilisateur: #{e.message}"
        puts "   Détails: #{e.backtrace.first}"
      end

      puts ""
      puts "📊 Statistiques actuelles:"
      puts "   👥 Total utilisateurs: #{User.count}"
      puts "   🏠 Total propriétés: #{Property.count}"
      puts "   🔧 Total projets: #{Project.count}"
    end

    desc "Ajouter seulement les utilisateurs manquants en développement (sans suppression)"
    task add_missing_users_dev: :environment do
      puts "👥 Ajout des utilisateurs manquants en développement..."
      puts "🛡️  Mode sécurisé : aucune suppression de données existantes"
      puts ""

      # Récupérer la liste complète des utilisateurs à créer
      # (copie de la structure du fichier seeds)
      users_data = [
        {
          email: 'robin@primes-services.be',
          password: 'robin123456',
          first_name: 'Robin',
          last_name: 'du Parc',
          role: 'admin',
          phone: '+32 2 123 45 67',
          city: 'Bruxelles',
          postal_code: '1000',
          test_user: true
        },
        {
          email: 'geraldine@primes-services.be',
          password: 'demo2025',
          first_name: 'Géraldine',
          last_name: 't Kint',
          role: 'user',
          phone: '+32 2 234 56 78',
          city: 'Bruxelles',
          postal_code: '1050',
          test_user: true
        }
        # Ajoutez ici tous les autres utilisateurs si nécessaire
        # Pour l'instant, on va juste compter les existants
      ]

      # Compter tous les utilisateurs actuels
      existing_count = User.count

      puts "📊 Utilisateurs actuellement en base : #{existing_count}"
      puts "🛡️  Aucune donnée supprimée - environnement de développement protégé"
      puts ""
      puts "💡 Si vous voulez forcer un nettoyage complet :"
      puts "   CLEANUP_DEV_DATA=true rails db:seed"
      puts ""
      puts "� Pour ajouter de nouveaux utilisateurs en production :"
      puts "   rails db:users:add_all_real_users"
    end

    desc "Ajouter tous les nouveaux utilisateurs réels en production"
    task add_all_real_users: :environment do
      puts "👥 Ajout de tous les nouveaux utilisateurs réels en production..."
      puts ""

      # Liste des 11 nouveaux utilisateurs réels
      new_real_users = [
        {
          email: 'baptiste@peintagone.be',
          password: 'Baptiste2025!Paint',
          first_name: 'BAPTISTE',
          last_name: 'PIESSEVAUX',
          phone: '+32 498 84 28 81',
          city: 'Mont Saint Guibert',
          postal_code: '1435'
        },
        {
          email: 'vmollica@yahoo.fr',
          password: 'Vincenzo2025!Secure',
          first_name: 'VINCENZO',
          last_name: 'MOLLICA',
          phone: '+32 472 49 95 32',
          city: 'IXELLES',
          postal_code: '1050'
        },
        {
          email: 'pvk@jour-j.be',
          password: 'Philippe2025!JourJ',
          first_name: 'PHILIPPE',
          last_name: 'VAN KERCKOVE',
          phone: '+32 475 71 80 31',
          city: 'BAISY THY',
          postal_code: '1470'
        },
        {
          email: 'ines@blancostudio.be',
          password: 'RobinInes2025!Studio',
          first_name: 'ROBIN/INES',
          last_name: 'DEGRYSE',
          phone: '+32 472 57 12 28',
          city: 'BRUXELLES',
          postal_code: '1000'
        },
        {
          email: 'baptiste.chatain@gmail.com',
          password: 'BaptisteChatain2025!',
          first_name: 'BAPTISTE',
          last_name: 'CHATAIN',
          phone: '+32 499 27 89 50',
          city: 'WATERLOO',
          postal_code: '1410'
        },
        {
          email: 'louise.tournay@icloud.com',
          password: 'Louise2025!Tournay',
          first_name: 'LOUISE',
          last_name: 'TOURNAY',
          phone: '+32 471 53 81 40',
          city: 'LASNE',
          postal_code: '1380'
        },
        {
          email: 'gaetan@cubeconstruct.be',
          password: 'Gaetan2025!Cube',
          first_name: 'GAETAN',
          last_name: 'NIEGO',
          phone: '+32 472 48 89 95',
          city: 'OVERIJSE',
          postal_code: '3090'
        },
        {
          email: 'eloot.jonathan@gmail.com',
          password: 'Jonathan2025!Eloot',
          first_name: 'JONATHAN',
          last_name: 'ELOOT',
          phone: '+32 479 05 00 84',
          city: 'FAYT LEZ MANAGE',
          postal_code: '7170'
        },
        {
          email: 'welcome.michelpotvin@gmail.com',
          password: 'Michel2025!Potvin',
          first_name: 'MICHEL',
          last_name: 'POTVIN',
          phone: '+32 476 43 64 77',
          city: 'NAMUR',
          postal_code: '5000'
        },
        {
          email: 'caroline.colot@gmail.com',
          password: 'Caroline2025!Colot',
          first_name: 'CAROLINE',
          last_name: 'COLOT',
          phone: '+32 472 63 03 28',
          city: 'LASNE',
          postal_code: '1380'
        },
        {
          email: 'd.raymond@delacroix-partners.be',
          password: 'Denis2025!Delacroix',
          first_name: 'DENIS',
          last_name: 'RAYMOND',
          phone: '+32 498 62 37 93',
          city: 'NAMUR',
          postal_code: '5000'
        }
      ]

      created_count = 0
      existing_count = 0
      error_count = 0

      new_real_users.each do |user_data|
        # Vérifier si l'utilisateur existe déjà
        existing_user = User.find_by(email: user_data[:email])

        if existing_user
          puts "⚠️  #{user_data[:email]} - EXISTE DÉJÀ"
          existing_count += 1
          next
        end

        begin
          user = User.create!(
            email: user_data[:email],
            password: user_data[:password],
            password_confirmation: user_data[:password],
            first_name: user_data[:first_name],
            last_name: user_data[:last_name],
            role: 'user',
            phone: user_data[:phone],
            city: user_data[:city],
            postal_code: user_data[:postal_code],
            confirmed_at: Time.current
          )

          puts "✅ #{user_data[:email]} - #{user_data[:first_name]} #{user_data[:last_name]} créé"
          created_count += 1

        rescue => e
          puts "❌ #{user_data[:email]} - ERREUR: #{e.message}"
          error_count += 1
        end
      end

      puts ""
      puts "📊 Résultats de l'ajout:"
      puts "   ✅ Créés avec succès: #{created_count}"
      puts "   ⚠️  Déjà existants: #{existing_count}"
      puts "   ❌ Erreurs: #{error_count}"
      puts ""
      puts "📊 Statistiques actuelles:"
      puts "   👥 Total utilisateurs: #{User.count}"
      puts "   🏠 Total propriétés: #{Property.count}"
      puts "   🔧 Total projets: #{Project.count}"

      if created_count > 0
        puts ""
        puts "🔑 MOTS DE PASSE GÉNÉRÉS - À COMMUNIQUER AUX CLIENTS:"
        new_real_users.each do |user_data|
          next if User.find_by(email: user_data[:email]).nil? # Si pas créé
          puts "   #{user_data[:email]} → #{user_data[:password]}"
        end
      end
    end

    desc "Lister tous les utilisateurs réels (non-test) de la base"
    task list_real_users: :environment do
      puts "👥 Utilisateurs réels dans la base de données:"
      puts ""

      # Utilisateurs avec emails externes (vrais clients)
      real_users = User.where.not("email LIKE ?", "%@primes-services.be")

      if real_users.empty?
        puts "ℹ️  Aucun utilisateur réel trouvé (emails externes)"
      else
        real_users.each do |user|
          puts "🔍 #{user.email}"
          puts "   👤 #{user.first_name} #{user.last_name}"
          puts "   🏙️  #{user.city} (#{user.postal_code})"
          puts "   📱 #{user.phone}"
          puts "   🏠 Propriétés: #{user.properties.count}"
          puts "   🔧 Projets: #{user.projects.count}"
          puts "   📅 Créé: #{user.created_at&.strftime('%d/%m/%Y à %H:%M')}"
          puts ""
        end

        puts "📊 Total: #{real_users.count} utilisateur(s) réel(s)"
      end
    end
  end
end
