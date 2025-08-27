namespace :backup do
  desc "Créer un backup complet des données critiques"
  task critical_data: :environment do
    puts "🛡️  BACKUP DONNÉES CRITIQUES"
    puts "=============================="
    
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    backup_dir = Rails.root.join('tmp', 'backups')
    FileUtils.mkdir_p(backup_dir)
    
    # 1. Backup Utilisateurs
    puts "👥 Export des utilisateurs..."
    users_file = backup_dir.join("users_#{timestamp}.json")
    users_data = User.all.map do |user|
      {
        id: user.id,
        email: user.email,
        encrypted_password: user.encrypted_password,
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role,
        phone: user.phone,
        city: user.city,
        postal_code: user.postal_code,
        confirmed_at: user.confirmed_at,
        created_at: user.created_at,
        updated_at: user.updated_at
      }
    end
    File.write(users_file, JSON.pretty_generate(users_data))
    puts "✅ Utilisateurs sauvés: #{users_file}"
    
    # 2. Backup Propriétés
    puts "🏠 Export des propriétés..."
    properties_file = backup_dir.join("properties_#{timestamp}.json")
    properties_data = Property.all.map do |property|
      {
        id: property.id,
        user_id: property.user_id,
        rue: property.rue,
        numero: property.numero,
        code_postal: property.code_postal,
        commune: property.commune,
        region: property.region,
        type_bien_bruxelles: property.type_bien_bruxelles,
        annee_construction: property.annee_construction,
        peb: property.peb,
        created_at: property.created_at,
        updated_at: property.updated_at
      }
    end
    File.write(properties_file, JSON.pretty_generate(properties_data))
    puts "✅ Propriétés sauvées: #{properties_file}"
    
    # 3. Backup Projets
    puts "🔧 Export des projets..."
    projects_file = backup_dir.join("projects_#{timestamp}.json")
    projects_data = Project.all.map do |project|
      {
        id: project.id,
        user_id: project.user_id,
        property_id: project.property_id,
        nom: project.nom,
        description: project.description,
        statut: project.statut,
        created_at: project.created_at,
        updated_at: project.updated_at
      }
    end
    File.write(projects_file, JSON.pretty_generate(projects_data))
    puts "✅ Projets sauvés: #{projects_file}"
    
    # 4. Statistiques
    puts ""
    puts "📊 Statistiques du backup:"
    puts "   - Utilisateurs: #{User.count}"
    puts "   - Propriétés: #{Property.count}"
    puts "   - Projets: #{Project.count}"
    puts "   - Date: #{Time.current}"
    
    puts ""
    puts "🎉 Backup terminé!"
    puts "📂 Fichiers dans: #{backup_dir}"
  end
  
  desc "Restaurer des données critiques depuis un backup JSON"
  task :restore_critical_data, [:timestamp] => :environment do |t, args|
    unless args[:timestamp]
      puts "❌ Usage: rake backup:restore_critical_data[20250827_143000]"
      exit 1
    end
    
    timestamp = args[:timestamp]
    backup_dir = Rails.root.join('tmp', 'backups')
    
    puts "⚠️  RESTAURATION DONNÉES CRITIQUES"
    puts "=================================="
    puts "📅 Timestamp: #{timestamp}"
    
    # Vérifier les fichiers
    users_file = backup_dir.join("users_#{timestamp}.json")
    properties_file = backup_dir.join("properties_#{timestamp}.json")
    projects_file = backup_dir.join("projects_#{timestamp}.json")
    
    unless File.exist?(users_file)
      puts "❌ Fichier utilisateurs non trouvé: #{users_file}"
      exit 1
    end
    
    puts "⚠️  Cette opération va ÉCRASER les données actuelles!"
    print "Tapez 'RESTORE' pour confirmer: "
    confirmation = STDIN.gets.chomp
    
    unless confirmation == 'RESTORE'
      puts "❌ Restauration annulée"
      exit 1
    end
    
    ActiveRecord::Base.transaction do
      # 1. Nettoyage
      puts "🧹 Suppression des données actuelles..."
      Project.destroy_all
      Property.destroy_all
      User.destroy_all
      
      # 2. Restauration Utilisateurs
      puts "👥 Restauration des utilisateurs..."
      users_data = JSON.parse(File.read(users_file))
      users_data.each do |user_attrs|
        User.create!(user_attrs.except('id'))
      end
      puts "✅ #{User.count} utilisateurs restaurés"
      
      # 3. Restauration Propriétés
      if File.exist?(properties_file)
        puts "🏠 Restauration des propriétés..."
        properties_data = JSON.parse(File.read(properties_file))
        properties_data.each do |property_attrs|
          Property.create!(property_attrs.except('id'))
        end
        puts "✅ #{Property.count} propriétés restaurées"
      end
      
      # 4. Restauration Projets
      if File.exist?(projects_file)
        puts "🔧 Restauration des projets..."
        projects_data = JSON.parse(File.read(projects_file))
        projects_data.each do |project_attrs|
          Project.create!(project_attrs.except('id'))
        end
        puts "✅ #{Project.count} projets restaurés"
      end
    end
    
    puts ""
    puts "🎉 Restauration terminée!"
    puts "📊 Données restaurées:"
    puts "   - Utilisateurs: #{User.count}"
    puts "   - Propriétés: #{Property.count}"
    puts "   - Projets: #{Project.count}"
  end
end
