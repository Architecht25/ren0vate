namespace :cleanup do
  desc "Nettoie les données relatives aux entreprises de l'application"
  task entreprise_data: :environment do
    puts "\n🔍 Analyse des données d'entreprise..."
    puts "=" * 60

    # 1. Vérifier les propriétés d'entreprise
    entreprise_properties = Property.where(type: 'entreprise')
    puts "\n📊 Propriétés de type 'entreprise': #{entreprise_properties.count}"

    if entreprise_properties.any?
      puts "\nDétails des propriétés d'entreprise:"
      entreprise_properties.each do |prop|
        puts "  - ID: #{prop.id} | Titre: #{prop.titre || 'N/A'} | Région: #{prop.region}"
        puts "    Projets associés: #{prop.projects.count}"
        puts "    Simulations associées: #{prop.simulations.count}"
      end
    end

    # 2. Vérifier les propriétés avec profil_demandeur entreprise
    properties_profil_entreprise = Property.where(profil_demandeur: 'entreprise')
    puts "\n📊 Propriétés avec profil_demandeur 'entreprise': #{properties_profil_entreprise.count}"

    if properties_profil_entreprise.any?
      puts "\nDétails:"
      properties_profil_entreprise.each do |prop|
        puts "  - ID: #{prop.id} | Titre: #{prop.titre || 'N/A'} | Type: #{prop.type}"
      end
    end

    # 3. Vérifier les projets de type investment
    investment_projects = Project.where(project_type: 'investment')
    puts "\n📊 Projets de type 'investment': #{investment_projects.count}"

    if investment_projects.any?
      puts "\nDétails des projets d'investissement:"
      investment_projects.each do |proj|
        puts "  - ID: #{proj.id} | Nom: #{proj.nom} | Utilisateur: #{proj.user.email}"
        puts "    Propriété: #{proj.property&.titre || 'N/A'}"
        puts "    Simulations: #{proj.simulations.count}"
      end
    end

    # 4. Vérifier les projets avec finalité économique
    economic_projects = Project.where(finalite: 'economique')
    puts "\n📊 Projets avec finalité 'economique': #{economic_projects.count}"

    if economic_projects.any?
      puts "\nDétails:"
      economic_projects.each do |proj|
        puts "  - ID: #{proj.id} | Nom: #{proj.nom} | Type: #{proj.project_type}"
      end
    end

    # 5. Vérifier les simulations d'entreprise
    entreprise_simulations = Simulation.where(category: 'entreprise')
    puts "\n📊 Simulations de catégorie 'entreprise': #{entreprise_simulations.count}"

    # Résumé
    puts "\n" + "=" * 60
    puts "📋 RÉSUMÉ"
    puts "=" * 60
    puts "Total des éléments à nettoyer:"
    total = entreprise_properties.count +
            properties_profil_entreprise.count +
            investment_projects.count +
            economic_projects.count +
            entreprise_simulations.count
    puts "  🔢 #{total} éléments trouvés"

    if total > 0
      puts "\n⚠️  Pour supprimer ces données, lancez:"
      puts "   rake cleanup:delete_entreprise_data"
    else
      puts "\n✅ Aucune donnée d'entreprise à nettoyer!"
    end
  end

  desc "Supprime les données relatives aux entreprises (ATTENTION: irréversible!)"
  task delete_entreprise_data: :environment do
    puts "\n⚠️  ATTENTION: Cette tâche va SUPPRIMER définitivement les données d'entreprise!"
    puts "=" * 60

    print "\nTapez 'CONFIRMER' pour continuer: "
    confirmation = STDIN.gets.chomp

    unless confirmation == 'CONFIRMER'
      puts "❌ Annulé."
      exit
    end

    puts "\n🗑️  Démarrage de la suppression..."

    # Compteurs
    deleted_counts = {
      properties: 0,
      projects: 0,
      simulations: 0
    }

    # 1. Supprimer les projets de type investment
    Project.where(project_type: 'investment').find_each do |project|
      puts "  Suppression du projet: #{project.nom} (ID: #{project.id})"
      project.destroy
      deleted_counts[:projects] += 1
    end

    # 2. Supprimer les projets avec finalité économique
    Project.where(finalite: 'economique').find_each do |project|
      puts "  Suppression du projet économique: #{project.nom} (ID: #{project.id})"
      project.destroy
      deleted_counts[:projects] += 1
    end

    # 3. Supprimer les simulations d'entreprise
    Simulation.where(category: 'entreprise').find_each do |simu|
      puts "  Suppression de la simulation entreprise (ID: #{simu.id})"
      simu.destroy
      deleted_counts[:simulations] += 1
    end

    # 4. Nettoyer ou supprimer les propriétés
    Property.where(type: 'entreprise').find_each do |prop|
      if prop.projects.where.not(project_type: 'investment').any? ||
         prop.simulations.where.not(category: 'entreprise').any?
        # Si la propriété a d'autres données, on convertit juste le type
        puts "  Conversion de la propriété: #{prop.titre} (ID: #{prop.id}) vers type 'appartement'"
        prop.update(type: 'appartement', profil_demandeur: 'proprietaire_occupant_ou_futur_occupant')
      else
        # Sinon on supprime
        puts "  Suppression de la propriété: #{prop.titre} (ID: #{prop.id})"
        prop.destroy
        deleted_counts[:properties] += 1
      end
    end

    # 5. Convertir les propriétés avec profil_demandeur entreprise
    Property.where(profil_demandeur: 'entreprise').update_all(
      profil_demandeur: 'proprietaire_occupant_ou_futur_occupant'
    )

    puts "\n" + "=" * 60
    puts "✅ NETTOYAGE TERMINÉ"
    puts "=" * 60
    puts "Éléments supprimés:"
    puts "  📦 Propriétés: #{deleted_counts[:properties]}"
    puts "  🏗️  Projets: #{deleted_counts[:projects]}"
    puts "  📊 Simulations: #{deleted_counts[:simulations]}"
    puts "\n✨ Base de données nettoyée!"
  end

  desc "Convertit les données d'entreprise en données résidentielles (conserve les données)"
  task convert_entreprise_to_residential: :environment do
    puts "\n🔄 Conversion des données d'entreprise en résidentiel..."
    puts "=" * 60

    converted_counts = {
      properties: 0,
      projects: 0
    }

    # 1. Convertir les projets investment en renovation
    Project.where(project_type: 'investment').find_each do |project|
      puts "  Conversion du projet: #{project.nom} (investment → renovation)"
      project.update(
        project_type: 'renovation',
        finalite: 'residentielle'
      )
      converted_counts[:projects] += 1
    end

    # 2. Convertir les projets économiques en résidentiels
    Project.where(finalite: 'economique').find_each do |project|
      puts "  Conversion de la finalité: #{project.nom} (economique → residentielle)"
      project.update(finalite: 'residentielle')
      converted_counts[:projects] += 1
    end

    # 3. Convertir les propriétés d'entreprise
    Property.where(type: 'entreprise').find_each do |prop|
      puts "  Conversion de la propriété: #{prop.titre || prop.id} (entreprise → appartement)"
      prop.update(
        type: 'appartement',
        profil_demandeur: 'proprietaire_occupant_ou_futur_occupant'
      )
      converted_counts[:properties] += 1
    end

    # 4. Convertir le profil demandeur entreprise
    count = Property.where(profil_demandeur: 'entreprise').update_all(
      profil_demandeur: 'proprietaire_occupant_ou_futur_occupant'
    )
    converted_counts[:properties] += count

    puts "\n" + "=" * 60
    puts "✅ CONVERSION TERMINÉE"
    puts "=" * 60
    puts "Éléments convertis:"
    puts "  📦 Propriétés: #{converted_counts[:properties]}"
    puts "  🏗️  Projets: #{converted_counts[:projects]}"
    puts "\n✨ Les données ont été converties en résidentiel!"
  end
end
