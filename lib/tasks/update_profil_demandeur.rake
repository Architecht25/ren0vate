namespace :data do
  desc "Met à jour le profil_demandeur pour les propriétés en Flandre"
  task update_profil_demandeur_flandre: :environment do
    puts "🔄 Mise à jour du profil_demandeur pour les propriétés en Flandre..."

    properties_updated = 0

    Property.where(region: 'flandre', profil_demandeur: [nil, '']).find_each do |property|
      # Valeur par défaut : propriétaire_occupant (la plus commune en Flandre)
      property.update!(profil_demandeur: 'proprietaire_occupant')
      puts "✅ Propriété #{property.id} - #{property.full_address} : profil_demandeur défini à 'proprietaire_occupant'"
      properties_updated += 1
    end

    puts "🎉 Mise à jour terminée ! #{properties_updated} propriétés mises à jour."
  end

  desc "Affiche les propriétés en Flandre sans profil_demandeur"
  task check_profil_demandeur_flandre: :environment do
    puts "🔍 Vérification des propriétés en Flandre sans profil_demandeur..."

    properties = Property.where(region: 'flandre', profil_demandeur: [nil, ''])

    if properties.any?
      puts "❌ #{properties.count} propriétés trouvées sans profil_demandeur :"
      properties.each do |property|
        puts "   - ID: #{property.id}, Adresse: #{property.full_address}"
      end
    else
      puts "✅ Toutes les propriétés en Flandre ont un profil_demandeur défini."
    end
  end
end
