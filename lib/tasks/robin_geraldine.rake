namespace :users do
  desc "Ajouter 3 propriétés et 5 projets à Robin et Géraldine"
  task add_properties_robin_geraldine: :environment do
    puts "🏠 AJOUT PROPRIÉTÉS ROBIN & GÉRALDINE"
    puts "====================================="
    
    # Trouver Robin et Géraldine
    robin = User.find_by(email: 'robin@primes-services.be')
    geraldine = User.find_by(email: 'geraldine@primes-services.be')
    
    unless robin && geraldine
      puts "❌ Robin ou Géraldine non trouvé(e)"
      exit 1
    end
    
    # Adresses Brussels pour les propriétés
    brussels_addresses = [
      { street: 'Avenue Louise 123', number: '123', street_name: 'Avenue Louise', city: 'Bruxelles', zipcode: '1050', municipality: 'Ixelles' },
      { street: 'Rue de la Loi 456', number: '456', street_name: 'Rue de la Loi', city: 'Bruxelles', zipcode: '1040', municipality: 'Etterbeek' },
      { street: 'Boulevard Anspach 789', number: '789', street_name: 'Boulevard Anspach', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
      { street: 'Avenue des Arts 321', number: '321', street_name: 'Avenue des Arts', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
      { street: 'Rue Royale 654', number: '654', street_name: 'Rue Royale', city: 'Bruxelles', zipcode: '1000', municipality: 'Bruxelles-Ville' },
      { street: 'Chaussée de Charleroi 987', number: '987', street_name: 'Chaussée de Charleroi', city: 'Bruxelles', zipcode: '1060', municipality: 'Saint-Gilles' }
    ]
    
    # Types de propriétés et projets
    property_types = ['Maison unifamiliale', 'Appartement', 'Maison de maître', 'Studio', 'Loft', 'Duplex']
    project_types = ['Isolation toiture', 'Pompe à chaleur', 'Panneaux solaires', 'Rénovation énergétique', 'Isolation façade', 'Chaudière condensation', 'VMC double flux', 'Isolation murs']
    
    [robin, geraldine].each do |user|
      puts ""
      puts "👤 Ajout pour #{user.first_name} #{user.last_name} (#{user.email})"
      
      # Créer 3 propriétés
      3.times do |prop_index|
        address = brussels_addresses.sample
        property_type = property_types.sample
        
        puts "  🏠 Propriété #{prop_index + 1}: #{address[:street]}"
        
        property = Property.create!(
          user: user,
          rue: address[:street_name],
          numero: address[:number],
          code_postal: address[:zipcode],
          commune: address[:municipality],
          region: 'bruxelles',
          type_bien_bruxelles: property_type,
          annee_construction: rand(1950..2020),
          peb: ['A', 'B', 'C', 'D', 'E', 'F', 'G'].sample
        )
        
        # Créer 5 projets pour cette propriété
        5.times do |proj_index|
          project_type = project_types.sample
          statut = ['preparation', 'en_cours', 'termine'].sample
          
          puts "    🔧 Projet #{proj_index + 1}: #{project_type}"
          
          Project.create!(
            user: user,
            property: property,
            nom: "#{project_type} - #{property.commune}",
            description: "Projet de #{project_type.downcase} pour améliorer l'efficacité énergétique du bien situé #{property.rue} #{property.numero}",
            statut: statut
          )
        end
      end
    end
    
    puts ""
    puts "✅ AJOUT TERMINÉ !"
    puts "📊 Nouvelles statistiques:"
    puts "   - Robin: #{robin.properties.count} propriétés, #{robin.projects.count} projets"
    puts "   - Géraldine: #{geraldine.properties.count} propriétés, #{geraldine.projects.count} projets"
    puts "   - Total général: #{User.count} utilisateurs, #{Property.count} propriétés, #{Project.count} projets"
  end
  
  desc "Statistiques détaillées Robin et Géraldine"
  task stats_robin_geraldine: :environment do
    puts "📊 STATISTIQUES ROBIN & GÉRALDINE"
    puts "================================="
    
    robin = User.find_by(email: 'robin@primes-services.be')
    geraldine = User.find_by(email: 'geraldine@primes-services.be')
    
    [robin, geraldine].each do |user|
      next unless user
      
      puts ""
      puts "👤 #{user.first_name} #{user.last_name} (#{user.email})"
      puts "   🏠 Propriétés: #{user.properties.count}"
      
      user.properties.each_with_index do |property, index|
        puts "      #{index + 1}. #{property.rue} #{property.numero}, #{property.commune} (#{property.projects.count} projets)"
      end
      
      puts "   🔧 Projets: #{user.projects.count}"
    end
    
    puts ""
    puts "📈 Total général:"
    puts "   - Utilisateurs: #{User.count}"
    puts "   - Propriétés: #{Property.count}"
    puts "   - Projets: #{Project.count}"
  end
end
