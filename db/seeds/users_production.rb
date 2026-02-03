# Seeds pour recréer les 20 utilisateurs production avec leurs données complètes
puts "👥 Création des utilisateurs de production..."

# Nettoyage préalable (optionnel et sécurisé)
if Rails.env.development?
  # Protection : demander confirmation avant de supprimer les données
  cleanup_env = ENV['CLEANUP_DEV_DATA']

  if cleanup_env == 'true'
    puts "🧹 Nettoyage des anciennes données utilisateurs en développement..."
    puts "⚠️  ATTENTION : Suppression de toutes les données de développement !"

    # Supprimer dans l'ordre pour éviter les contraintes de clés étrangères
    puts "  🗑️  Suppression des request_progresses..."
    RequestProgress.destroy_all if defined?(RequestProgress)

    puts "  🗑️  Suppression des requests..."
    Request.destroy_all if defined?(Request)

    puts "  🗑️  Suppression des projets..."
    Project.destroy_all

    puts "  🗑️  Suppression des propriétés..."
    Property.destroy_all

    puts "  🗑️  Suppression des utilisateurs..."
    User.destroy_all

    puts "  ✅ Nettoyage terminé"
  else
    puts "🛡️  PROTECTION ACTIVÉE - Données de développement préservées"
    puts "ℹ️  Pour forcer le nettoyage, utilisez : CLEANUP_DEV_DATA=true rails db:seed"
    puts "ℹ️  Seuls les nouveaux utilisateurs manquants seront créés..."
    puts ""
  end
end

# Liste des 20 utilisateurs avec leurs profils complets
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
    test_user: true  # Utilisateur de test
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
    test_user: true  # Utilisateur de test
  },
  {
    email: 'anne@primes-services.be',
    password: 'demo2025',
    first_name: 'Anne',
    last_name: 'Dao',
    role: 'user',
    phone: '+32 2 456 78 90',
    city: 'Uccle',
    postal_code: '1180',
    test_user: true  # Utilisateur de test
  },
  {
    email: 'sabenca@primes-services.be',
    password: 'demo2025',
    first_name: 'Sabenca',
    last_name: 'Ozile',
    role: 'user',
    phone: '+32 2 567 89 01',
    city: 'Saint-Gilles',
    postal_code: '1060',
    test_user: true  # Utilisateur de test
  },
  # === VRAIS CLIENTS (pas de données fictives) ===
  {
    email: 'laes.michael@gmail.com',
    password: 'Michael2025!Secure',
    first_name: 'MICHAEL',
    last_name: 'LAES',
    role: 'user',
    phone: '+32476794725',
    city: 'OVERIJSE',
    postal_code: '3090',
    test_user: false  # Vrai client - pas de données fictives
  },
  {
    email: 'baptiste@peintagone.be',
    password: 'Baptiste2025!Paint',
    first_name: 'BAPTISTE',
    last_name: 'PIESSEVAUX',
    role: 'user',
    phone: '+32 498 84 28 81',
    city: 'Mont Saint Guibert',
    postal_code: '1435',
    test_user: false  # Vrai client - pas de données fictives
  },
  {
    email: 'vmollica@yahoo.fr',
    password: 'Vincenzo2025!Secure',
    first_name: 'VINCENZO',
    last_name: 'MOLLICA',
    role: 'user',
    phone: '+32 472 49 95 32',
    city: 'IXELLES',
    postal_code: '1050',
    test_user: false  # Vrai client - pas de données fictives
  },
  {
    email: 'pvk@jour-j.be',
    password: 'Philippe2025!JourJ',
    first_name: 'PHILIPPE',
    last_name: 'VAN KERCKOVE',
    role: 'user',
    phone: '+32 475 71 80 31',
    city: 'BAISY THY',
    postal_code: '1470',
    test_user: false  # Vrai client - pas de données fictives
  },
  {
    email: 'ines@blancostudio.be',
    password: 'RobinInes2025!Studio',
    first_name: 'ROBIN/INES',
    last_name: 'DEGRYSE',
    role: 'user',
    phone: '+32 472 57 12 28',
    city: 'BRUXELLES',
    postal_code: '1000',
    test_user: false  # Vrai client - pas de données fictives
  },
  {
    email: 'baptiste.chatain@gmail.com',
    password: 'BaptisteChatain2025!',
    first_name: 'BAPTISTE',
    last_name: 'CHATAIN',
    role: 'user',
    phone: '+32 499 27 89 50',
    city: 'WATERLOO',
    postal_code: '1410',
    test_user: false  # Vrai client - pas de données fictives
  },
  {
    email: 'louise.tournay@icloud.com',
    password: 'Louise2025!Tournay',
    first_name: 'LOUISE',
    last_name: 'TOURNAY',
    role: 'user',
    phone: '+32 471 53 81 40',
    city: 'LASNE',
    postal_code: '1380',
    test_user: false  # Vrai client - pas de données fictives
  },
  {
    email: 'gaetan@cubeconstruct.be',
    password: 'Gaetan2025!Cube',
    first_name: 'GAETAN',
    last_name: 'NIEGO',
    role: 'user',
    phone: '+32 472 48 89 95',
    city: 'OVERIJSE',
    postal_code: '3090',
    test_user: false  # Vrai client - pas de données fictives
  },
  {
    email: 'eloot.jonathan@gmail.com',
    password: 'Jonathan2025!Eloot',
    first_name: 'JONATHAN',
    last_name: 'ELOOT',
    role: 'user',
    phone: '+32 479 05 00 84',
    city: 'FAYT LEZ MANAGE',
    postal_code: '7170',
    test_user: false  # Vrai client - pas de données fictives
  },
  {
    email: 'welcome.michelpotvin@gmail.com',
    password: 'Michel2025!Potvin',
    first_name: 'MICHEL',
    last_name: 'POTVIN',
    role: 'user',
    phone: '+32 476 43 64 77',
    city: 'NAMUR',
    postal_code: '5000',
    test_user: false  # Vrai client - pas de données fictives
  },
  {
    email: 'caroline.colot@gmail.com',
    password: 'Caroline2025!Colot',
    first_name: 'CAROLINE',
    last_name: 'COLOT',
    role: 'user',
    phone: '+32 472 63 03 28',
    city: 'LASNE',
    postal_code: '1380',
    test_user: false  # Vrai client - pas de données fictives
  },
  {
    email: 'd.raymond@delacroix-partners.be',
    password: 'Denis2025!Delacroix',
    first_name: 'DENIS',
    last_name: 'RAYMOND',
    role: 'user',
    phone: '+32 498 62 37 93',
    city: 'NAMUR',
    postal_code: '5000',
    test_user: false  # Vrai client - pas de données fictives
  },
  {
    email: 'nicolasbekaert@hotmail.com',
    password: 'Nicolas2025!Bekaert',
    first_name: 'NICOLAS',
    last_name: 'BEKAERT',
    role: 'user',
    phone: '+32 489 99 25 33',
    city: 'CHAUMONT-GISTOUX',
    postal_code: '1325',
    test_user: false  # Vrai client - pas de données fictives
  },
  # === NOUVEAUX CLIENTS 2025 ===
  {
    email: 'christineheeger@phoenixexecutive.com',
    password: 'Client2025!',
    first_name: 'Christine',
    last_name: 'Heeger',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'vitanzat@yahoo.fr',
    password: 'Client2025!',
    first_name: 'Terenzio',
    last_name: 'Vitanza',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'anne-sophie.clement@dpgmedia.be',
    password: 'Client2025!',
    first_name: 'Anne-Sophie',
    last_name: 'Clement',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'autosmasri@gmail.com',
    password: 'Client2025!',
    first_name: 'Raafat',
    last_name: 'Masri',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'zambranobraundiego@gmail.com',
    password: 'Client2025!',
    first_name: 'Diego',
    last_name: 'Zambrano Braun',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'fredericsc@hotmail.com',
    password: 'Client2025!',
    first_name: 'Frederic',
    last_name: 'Scouarnec',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'gbcprojct@gmail.com',
    password: 'Client2025!',
    first_name: 'Gauthier',
    last_name: 'Coutelier',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'sebastien.collard@howdensarton.com',
    password: 'Client2025!',
    first_name: 'Sébastien',
    last_name: 'Collard',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'geigerkenny@hotmail.fr',
    password: 'Client2025!',
    first_name: 'Kenny',
    last_name: 'Geiger',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'cedricdecock@live.be',
    password: 'Client2025!',
    first_name: 'Cédric',
    last_name: 'De Cock',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'cedric.delespaux@gmail.com',
    password: 'Client2025!',
    first_name: 'Cédric',
    last_name: 'Delespaux',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'emilie.goubau@icloud.com',
    password: 'Client2025!',
    first_name: 'Emilie',
    last_name: 'Gobeau',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'vandiest_patrick@lilly.com',
    password: 'Client2025!',
    first_name: 'Patrick',
    last_name: 'Vandiest',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'gary.cammermans@gmail.com',
    password: 'Client2025!',
    first_name: 'Gary',
    last_name: 'Cammermans',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'info@apachcompany.com',
    password: 'Client2025!',
    first_name: 'Pierre-Alexandre',
    last_name: 'Folcken',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'ancrenova@gmail.com',
    password: 'Client2025!',
    first_name: 'Alexei',
    last_name: 'Cozubovschi',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'mathieu@lokale.bio',
    password: 'Client2025!',
    first_name: 'MATHIEU',
    last_name: 'GUEGAN',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'sarah.levran@yahoo.com',
    password: 'Client2025!',
    first_name: 'Sarah',
    last_name: 'Levran',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'gaetanvdb1412@gmail.com',
    password: 'Client2025!',
    first_name: 'Gaétan',
    last_name: 'van der Bruggen',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'eugcy5@gmail.com',
    password: 'Client2025!',
    first_name: 'Eugenie',
    last_name: 'De Cartier',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'thceinos@hotmail.com',
    password: 'Client2025!',
    first_name: 'Thierry',
    last_name: 'Ceinos',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'arnaud.vanderroost@hotmail.be',
    password: 'Client2025!',
    first_name: 'Arnaud',
    last_name: 'Vanderroost',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'gilles_vb@hotmail.com',
    password: 'Client2025!',
    first_name: 'Gilles',
    last_name: 'Van Buggenhoudt',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'yh.callebaut@gmail.com',
    password: 'Client2025!',
    first_name: 'Yves',
    last_name: 'Callebaut',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'cv@thespin.be',
    password: 'Client2025!',
    first_name: 'Cedric',
    last_name: 'Vandermot',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'astubbe@stulis.be',
    password: 'Client2025!',
    first_name: 'Alain',
    last_name: 'Stubbe',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'vittoriopellizzari@hotmail.com',
    password: 'Client2025!',
    first_name: 'Vittorio',
    last_name: 'Pellizzari',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'irumutesi@hotmail.com',
    password: 'Client2025!',
    first_name: 'Irene',
    last_name: 'Umutesi',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'diego.depotter@familypartners.eu',
    password: 'Client2025!',
    first_name: 'Diego',
    last_name: 'de Potter',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'diane.querton@gmail.com',
    password: 'Client2025!',
    first_name: 'Diane',
    last_name: 'Querton',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'farrah.moh@gmail.com',
    password: 'Client2025!',
    first_name: 'Farrah',
    last_name: 'Mohammadi',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'carlasofnoah2@hotmail.be',
    password: 'Client2025!',
    first_name: 'Carla',
    last_name: 'Lourenco',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  # === NOUVEAUX CLIENTS NOVEMBRE 2025 (30 nouveaux) ===
  {
    email: 'alinette123@hotmail.com',
    password: 'Client2025!',
    first_name: 'Aline',
    last_name: 'De Cartier',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'c.heynderickx@gmail.com',
    password: 'Client2025!',
    first_name: 'Charles',
    last_name: 'Heynderickx',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'sarah.vanzeebroeck@gmail.com',
    password: 'Client2025!',
    first_name: 'Sarah',
    last_name: 'Van Zeebroeck - OLBRECHTS',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'ar-te@proximus.be',
    password: 'Client2025!',
    first_name: 'Nicole',
    last_name: 'VANDERHAEGHE',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'jeremie_vdm@hotmail.com',
    password: 'Client2025!',
    first_name: 'Jérémie',
    last_name: 'Vander Meuter',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 't.lehardy@shape.law',
    password: 'Client2025!',
    first_name: 'Thibault',
    last_name: 'Le Hardy',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'marc.hanssens@ing.com',
    password: 'Client2025!',
    first_name: 'Marc',
    last_name: 'Hanssens',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'lobillen@hotmail.com',
    password: 'Client2025!',
    first_name: 'Grégory',
    last_name: 'Billen - Ardouille',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'arnaudstapels@gmail.com',
    password: 'Client2025!',
    first_name: 'Arnaud',
    last_name: 'Stapels',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'kristinawillard@icloud.com',
    password: 'Client2025!',
    first_name: 'Kristina',
    last_name: 'Willard - pas',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'frederick.vanderelst@napton.be',
    password: 'Client2025!',
    first_name: 'Frederick',
    last_name: 'vander elst',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'leegc@outlook.be',
    password: 'Client2025!',
    first_name: '',
    last_name: 'Talib',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'quentinjottrand@hotmail.com',
    password: 'Client2025!',
    first_name: 'Quentin',
    last_name: 'Jottrand - TEST RENOVATE',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'sebastien.piaget@gmail.com',
    password: 'Client2025!',
    first_name: 'Sébastien',
    last_name: 'Piaget - primes temporaires 2025',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'michelkr@roodenbeke.be',
    password: 'Client2025!',
    first_name: 'Michel',
    last_name: "T'Kint de Roodenbeke",
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'emiliegenart1@gmail.com',
    password: 'Client2025!',
    first_name: 'Emilie',
    last_name: 'Genart',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'strang.mike.mg@gmail.com',
    password: 'Client2025!',
    first_name: 'Mike',
    last_name: 'Strang - appart 26-1',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'beatrice.vdsw@gmail.com',
    password: 'Client2025!',
    first_name: 'Béatrice',
    last_name: 'Vander Straten - TEST RENOVATE',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'bernarddelecourt1@gmail.com',
    password: 'Client2025!',
    first_name: 'Bernard',
    last_name: 'de le Court - DISTRAIT',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'kennethstewart80@hotmail.com',
    password: 'Client2025!',
    first_name: 'Kenneth',
    last_name: 'Stewart - rénopack-rénoprêt',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'stephanie.walckiers@gmail.com',
    password: 'Client2025!',
    first_name: 'Stéphanie',
    last_name: 'Biebuyck',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'm.vansteenbergh@skynet.be',
    password: 'Client2025!',
    first_name: 'Michel',
    last_name: 'VAN STEENBERGH',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'julieanciaux@hotmail.com',
    password: 'Client2025!',
    first_name: 'Julie',
    last_name: 'ANCIAUX',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'julieverbeke@me.com',
    password: 'Client2025!',
    first_name: 'Chantal',
    last_name: 'Verbaere',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'stephane.marcks@gmail.com',
    password: 'Client2025!',
    first_name: 'Stéphane',
    last_name: 'Marcks',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'pierre_close@hotmail.com',
    password: 'Client2025!',
    first_name: 'Pierre',
    last_name: 'Close',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  },
  {
    email: 'melody.lafleur.89@gmail.com',
    password: 'Melody2025!Secure',
    first_name: 'Melody',
    last_name: 'Lafleur',
    role: 'user',
    phone: '',
    city: '',
    postal_code: '',
    test_user: false
  }
]

# Adresses Brussels pour les propriétés
brussels_addresses = [
  { street: 'Rue de la Loi 15', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
  { street: 'Avenue Louise 234', city: 'Bruxelles', zipcode: '1050', municipality: 'Ixelles' },
  { street: 'Boulevard Anspach 67', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
  { street: 'Chaussée de Charleroi 123', city: 'Bruxelles', zipcode: '1060', municipality: 'Saint-Gilles' },
  { street: 'Avenue des Arts 89', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
  { street: 'Rue Royale 145', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
  { street: 'Place Eugène Flagey 12', city: 'Bruxelles', zipcode: '1050', municipality: 'Ixelles' },
  { street: 'Avenue Molière 78', city: 'Bruxelles', zipcode: '1180', municipality: 'Uccle' },
  { street: 'Rue de la Régence 34', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
  { street: 'Boulevard de Waterloo 91', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' }
]

# Types de propriétés et projets
property_types = ['Maison unifamiliale', 'Appartement', 'Maison de maître', 'Studio', 'Loft']
project_types = ['Isolation toiture', 'Pompe à chaleur', 'Panneaux solaires', 'Rénovation énergétique', 'Isolation façade']

created_users = []

# Création des utilisateurs
users_data.each_with_index do |user_data, index|
  existing_user = User.find_by(email: user_data[:email])

  if existing_user
    puts "⚠️  Utilisateur déjà existant: #{user_data[:email]} - ignoré"
    created_users << existing_user
    next
  end

  puts "👤 Création utilisateur: #{user_data[:email]}"

  user = User.create!(
    email: user_data[:email],
    password: user_data[:password],
    password_confirmation: user_data[:password],
    first_name: user_data[:first_name],
    last_name: user_data[:last_name],
    role: user_data[:role],
    phone: user_data[:phone],
    city: user_data[:city],
    postal_code: user_data[:postal_code],
    confirmed_at: Time.current
  )

  created_users << user

  # Créer 3 propriétés pour chaque utilisateur de test (sauf admin et vrais clients)
  next if user.role == 'admin' || user_data[:test_user] == false

  puts "  🏠 Génération de propriétés de test pour #{user.email}"

  3.times do |prop_index|
    address = brussels_addresses.sample
    property_type = property_types.sample

    puts "  🏠 Propriété #{prop_index + 1}: #{address[:street]}"

    # Parse street address into number and street name
    street_parts = address[:street].split(' ', 2)
    numero = street_parts.first
    rue = street_parts.size > 1 ? street_parts[1..-1].join(' ') : address[:street]

    property = Property.create!(
      user: user,
      rue: rue,
      numero: numero,
      code_postal: address[:zipcode],
      commune: address[:municipality],
      region: 'bruxelles',
      type_bien_bruxelles: property_type,
      annee_construction: rand(1950..2020),
      peb: ['A', 'B', 'C', 'D', 'E'].sample
    )

    # Créer 2-4 projets pour chaque propriété
    rand(2..4).times do |proj_index|
      project_type = project_types.sample
      statut = ['preparation', 'en_cours', 'termine'].sample

      puts "    🔧 Projet #{proj_index + 1}: #{project_type}"

      Project.create!(
        user: user,
        property: property,
        nom: "#{project_type} - #{property.commune}",
        description: "Projet de #{project_type.downcase} pour améliorer l'efficacité énergétique",
        statut: statut
      )
    end
  end
end

puts ""
puts "✅ Seed utilisateurs terminé!"
puts "📊 Statistiques:"
puts "  👥 Utilisateurs créés: #{created_users.size}"
puts "  🏠 Propriétés créées: #{Property.count}"
puts "  🔧 Projets créés: #{Project.count}"
puts ""
puts "🔑 Accès admin:"
puts "  📧 Email: robin@primes-services.be"
puts "  🔐 Mot de passe: robin123456"
puts ""
puts "🔑 Accès utilisateurs demo:"
puts "  📧 Email: [n'importe lequel des autres emails]"
puts "  🔐 Mot de passe: demo2025"
