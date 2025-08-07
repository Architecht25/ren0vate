namespace :properties do
  desc "Rattacher les propriétés de test à un utilisateur actif"
  task migrate_test_properties: :environment do
    puts "🔄 Migration des propriétés de test..."

    # Trouver les propriétés de test
    test_properties = Property.where(
      rue: ["Rue de l'Énergie", "Energiestraat", "Rue de la Paix"]
    )

    if test_properties.empty?
      puts "  ℹ️  Aucune propriété de test trouvée"
      return
    end

    # Trouver un utilisateur actif approprié
    target_user = User.joins(:properties).group('users.id').order('COUNT(properties.id) DESC').first ||
                  User.order(created_at: :desc).first

    if target_user.nil?
      puts "  ❌ Aucun utilisateur cible trouvé"
      return
    end

    puts "  👤 Utilisateur cible : #{target_user.email.gsub(/.{3,}@/, '***@')}"

    test_properties.each do |property|
      old_user_id = property.user_id
      property.update!(user_id: target_user.id)
      puts "  ✅ #{property.full_address} → transférée de l'utilisateur #{old_user_id} vers #{target_user.id}"
    end

    puts "✅ Migration terminée : #{test_properties.count} propriétés transférées"
  end
end
