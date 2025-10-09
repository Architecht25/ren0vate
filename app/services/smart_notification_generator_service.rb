class SmartNotificationGeneratorService
  def self.generate_all
    new.generate_all
  end

  def generate_all
    puts "🚀 Génération de notifications intelligentes..."

    results = {
      profile_completion: generate_profile_completion_notifications,
      property_setup: generate_property_setup_notifications,
      simulation_encouragement: generate_simulation_encouragement_notifications,
      geocoding_issues: generate_geocoding_notifications,
      admin_insights: generate_admin_notifications,
      engagement: generate_user_engagement_notifications
    }

    total_created = results.values.sum
    puts "✅ #{total_created} notifications générées avec succès!"

    results
  end

  private

  # Notifications pour compléter les profils
  def generate_profile_completion_notifications
    count = 0

    User.includes(:notifications).each do |user|
      missing_fields = []
      missing_fields << 'téléphone' if user.phone.blank?
      missing_fields << 'ville' if user.city.blank?
      missing_fields << 'code postal' if user.postal_code.blank?
      missing_fields << 'prénom' if user.first_name.blank?
      missing_fields << 'nom' if user.last_name.blank?

      if missing_fields.any?
        # Vérifier qu'on n'a pas déjà envoyé cette notification récemment
        unless user.notifications.where(
          type: 'document_requis',
          created_at: 7.days.ago..Time.current
        ).where("message LIKE ?", "%profil%").exists?

          Notification.create!(
            user: user,
            type: 'document_requis',
            category: 'systeme',
            priority: 'normale',
            title: '📝 Complétez votre profil pour une meilleure expérience',
            message: "Bonjour #{user.first_name || 'cher utilisateur'} ! Pour optimiser vos simulations de primes, merci de compléter les informations manquantes : #{missing_fields.join(', ')}. Un profil complet vous permet d'obtenir des résultats plus précis.",
            action_url: '/profile/edit'
          )
          count += 1
        end
      end
    end

    count
  end

  # Notifications pour encourager l'ajout de propriétés
  def generate_property_setup_notifications
    count = 0

    users_without_properties = User.left_joins(:properties)
                                  .where(properties: { id: nil })
                                  .includes(:notifications)

    users_without_properties.each do |user|
      # Utilisateurs inscrits depuis plus de 3 jours sans propriété
      if user.created_at < 3.days.ago
        unless user.notifications.where(
          type: 'etape_suivante',
          created_at: 5.days.ago..Time.current
        ).where("message LIKE ?", "%propriété%").exists?

          Notification.create!(
            user: user,
            type: 'etape_suivante',
            category: 'projets',
            priority: 'haute',
            title: '🏠 Ajoutez votre première propriété',
            message: "Bonjour #{user.first_name || user.email} ! Pour commencer à simuler vos primes de rénovation, ajoutez d'abord votre propriété. C'est rapide et cela vous donnera accès à toutes les primes disponibles pour votre région.",
            action_url: '/properties/new'
          )
          count += 1
        end
      end
    end

    count
  end

  # Notifications pour encourager les simulations
  def generate_simulation_encouragement_notifications
    count = 0

    # Propriétés sans simulations
    properties_without_simulations = Property.left_joins(:simulations)
                                           .where(simulations: { id: nil })
                                           .includes(:user, user: :notifications)

    properties_without_simulations.each do |property|
      user = property.user

      # Propriétés ajoutées depuis plus de 2 jours sans simulation
      if property.created_at < 2.days.ago
        unless user.notifications.where(
          type: 'prime_eligible',
          property: property,
          created_at: 5.days.ago..Time.current
        ).exists?

          # Calculer les primes potentielles pour cette région
          region = determine_region_from_postal_code(property.code_postal)
          prime_count = Prime.where(region: region).count

          Notification.create!(
            user: user,
            property: property,
            type: 'prime_eligible',
            category: 'primes',
            priority: 'haute',
            title: "💰 #{prime_count} primes disponibles pour votre propriété !",
            message: "Votre propriété #{property.rue} #{property.numero} à #{property.code_postal} peut bénéficier de #{prime_count} primes différentes en région #{region.capitalize}. Lancez une simulation pour découvrir le montant exact !",
            action_url: "/properties/#{property.id}/simulations/new"
          )
          count += 1
        end
      end
    end

    count
  end

  # Notifications pour les problèmes de géocodage
  def generate_geocoding_notifications
    count = 0

    ungeocoded_properties = Property.where(latitude: nil, longitude: nil)
                                  .includes(:user, user: :notifications)

    ungeocoded_properties.each do |property|
      user = property.user

      unless user.notifications.where(
        type: 'verification_requise',
        property: property,
        created_at: 10.days.ago..Time.current
      ).exists?

        Notification.create!(
          user: user,
          property: property,
          type: 'verification_requise',
          category: 'systeme',
          priority: 'normale',
          title: '📍 Vérification d\'adresse requise',
          message: "L'adresse de votre propriété #{property.rue} #{property.numero}, #{property.code_postal} nécessite une vérification pour optimiser la recherche de primes. Merci de vérifier l'exactitude de l'adresse.",
          action_url: "/properties/#{property.id}/edit"
        )
        count += 1
      end
    end

    count
  end

  # Notifications administratives basées sur les statistiques
  def generate_admin_notifications
    count = 0
    admin_users = User.admin

    return 0 if admin_users.empty?

    admin_users.each do |admin|
      # Notification de rapport hebdomadaire
      unless admin.notifications.where(
        type: 'admin_info',
        created_at: 6.days.ago..Time.current
      ).where("title LIKE ?", "%Rapport%").exists?

        stats = AdminStatsService.call

        Notification.create!(
          user: admin,
          type: 'admin_info',
          category: 'systeme',
          priority: 'normale',
          title: '📊 Rapport hebdomadaire de la plateforme',
          message: "Rapport d'activité : #{stats[:users][:total]} utilisateurs (+#{stats[:users][:recent_signups]} cette semaine), #{stats[:properties][:total]} propriétés (#{stats[:properties][:geocoding_rate].round(1)}% géocodées), #{stats[:simulations][:total]} simulations réalisées. #{stats[:geographic][:top_cities].count} villes actives.",
          action_url: '/admin/dashboard'
        )
        count += 1
      end

      # Alerte pour propriétés non géocodées
      ungeocoded_count = Property.where(latitude: nil, longitude: nil).count
      if ungeocoded_count > 5
        unless admin.notifications.where(
          type: 'admin_urgent',
          created_at: 3.days.ago..Time.current
        ).where("message LIKE ?", "%géocodage%").exists?

          Notification.create!(
            user: admin,
            type: 'admin_urgent',
            category: 'maintenance',
            priority: 'haute',
            title: '⚠️ Problèmes de géocodage détectés',
            message: "#{ungeocoded_count} propriétés ne sont pas géocodées, ce qui peut affecter la précision des simulations. Action recommandée : lancer le géocodage automatique.",
            action_url: '/admin/dashboard#geocode-action'
          )
          count += 1
        end
      end

      # Notification pour nouvelles primes (si pertinent)
      recent_primes = Prime.where('created_at > ?', 7.days.ago).count
      if recent_primes > 0
        unless admin.notifications.where(
          type: 'admin_nouvelle_prime',
          created_at: 7.days.ago..Time.current
        ).exists?

          Notification.create!(
            user: admin,
            type: 'admin_nouvelle_prime',
            category: 'primes',
            priority: 'normale',
            title: '🆕 Nouvelles primes ajoutées',
            message: "#{recent_primes} nouvelles primes ont été ajoutées cette semaine. Les utilisateurs peuvent maintenant bénéficier de ces nouvelles opportunités de financement.",
            action_url: '/admin/primes'
          )
          count += 1
        end
      end
    end

    count
  end

  # Notifications pour encourager l'engagement
  def generate_user_engagement_notifications
    count = 0

    # Utilisateurs avec simulations anciennes
    User.joins(:simulations)
        .where('simulations.created_at < ?', 30.days.ago)
        .where('simulations.created_at > ?', 90.days.ago)
        .distinct
        .includes(:notifications)
        .each do |user|

      unless user.notifications.where(
        type: 'conseil_optimisation',
        created_at: 15.days.ago..Time.current
      ).exists?

        latest_simulation = user.simulations.order(created_at: :desc).first
        days_old = (Date.current - latest_simulation.created_at.to_date).to_i

        Notification.create!(
          user: user,
          simulation: latest_simulation,
          type: 'conseil_optimisation',
          category: 'simulations',
          priority: 'normale',
          title: '🔄 Mettez à jour vos simulations',
          message: "Votre dernière simulation date de #{days_old} jours. Les montants des primes et les conditions peuvent avoir évolué. Nous vous recommandons de refaire une simulation pour des résultats actualisés.",
          action_url: "/simulations/new"
        )
        count += 1
      end
    end

    count
  end

  # Méthode utilitaire pour déterminer la région
  def determine_region_from_postal_code(postal_code)
    return 'inconnue' if postal_code.blank?

    case postal_code.to_s.first
    when '1'
      'bruxelles'
    when '2', '3'
      'flandre'
    when '4', '5', '6', '7'
      'wallonie'
    else
      'inconnue'
    end
  end
end
