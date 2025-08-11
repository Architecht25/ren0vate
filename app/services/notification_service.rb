class NotificationService
  class << self
    # Vérifier et créer les notifications automatiques pour tous les utilisateurs
    def generate_automatic_notifications
      User.includes(:properties, :projects, :simulations, :documents).find_each do |user|
        check_incomplete_dossiers(user)
        check_missing_invoices(user)
        check_upcoming_deadlines(user)
        check_expiring_simulations(user)
        check_optimization_opportunities(user)
        check_next_steps(user)
      end
    end

    # Vérifier les dossiers incomplets
    def check_incomplete_dossiers(user)
      user.properties.each do |property|
        missing_docs = []

        # Vérifier les documents requis par type
        required_doc_types = %w[devis facture certificat_peb]
        required_doc_types.each do |doc_type|
          unless property.documents.where(type_document: doc_type, status: 'approved').exists?
            missing_docs << doc_type.humanize
          end
        end

        if missing_docs.any?
          # Éviter les doublons récents
          unless user.notifications.where(
            type: 'dossier_incomplet',
            property: property,
            created_at: 7.days.ago..Time.current
          ).exists?
            Notification.create_dossier_incomplet(user, property, missing_docs)
          end
        end
      end
    end

    # Vérifier les factures manquantes
    def check_missing_invoices(user)
      user.projects.each do |project|
        # Si le projet a des devis mais pas de factures
        if project.documents.where(type_document: 'devis').exists? &&
           !project.documents.where(type_document: 'facture').exists? &&
           project.created_at < 15.days.ago

          unless user.notifications.where(
            type: 'facture_manquante',
            project: project,
            created_at: 5.days.ago..Time.current
          ).exists?
            Notification.create_facture_manquante(user, project, "rénovation énergétique")
          end
        end
      end
    end

    # Vérifier les deadlines proches
    def check_upcoming_deadlines(user)
      # Exemple : deadline pour soumission de dossier
      user.simulations.each do |simulation|
        if simulation.created_at < 80.days.ago && simulation.updated_at < 10.days.ago
          deadline = simulation.created_at + 90.days
          days_left = (deadline.to_date - Date.current).to_i

          if days_left <= 7 && days_left > 0
            unless user.notifications.where(
              type: 'deadline_proche',
              simulation: simulation,
              created_at: 2.days.ago..Time.current
            ).exists?
              Notification.create_deadline_proche(user, deadline, "soumission de votre dossier de primes")
            end
          end
        end
      end
    end

    # Vérifier les simulations qui vont expirer
    def check_expiring_simulations(user)
      user.simulations.where('created_at < ?', 75.days.ago).each do |simulation|
        days_left = 90 - (Date.current - simulation.created_at.to_date).to_i

        if days_left <= 15 && days_left > 0
          unless user.notifications.where(
            type: 'simulation_expiration',
            simulation: simulation,
            created_at: 5.days.ago..Time.current
          ).exists?
            Notification.create_simulation_expiration(user, simulation, days_left)
          end
        end
      end
    end

    # Identifier les opportunités d'optimisation
    def check_optimization_opportunities(user)
      user.simulations.recent.limit(3).each do |simulation|
        conseils = []

        # Logique d'exemple pour des conseils d'optimisation
        if simulation.respond_to?(:total_amount) && simulation.total_amount.to_i < 5000
          conseils << "Vous pourriez combiner plusieurs travaux pour augmenter vos primes de #{(5000 - simulation.total_amount.to_i)}€"
        end

        # Si l'utilisateur n'a fait qu'une simulation
        if user.simulations.count == 1
          conseils << "Avez-vous pensé aux primes pour l'isolation ? Elles peuvent être très avantageuses."
        end

        conseils.each do |conseil|
          unless user.notifications.where(
            type: 'conseil_optimisation',
            simulation: simulation,
            message: conseil,
            created_at: 14.days.ago..Time.current
          ).exists?
            Notification.create_conseil_optimisation(user, simulation, conseil)
          end
        end
      end
    end

    # Suggérer les prochaines étapes
    def check_next_steps(user)
      # Si l'utilisateur a fait une simulation mais pas de projet
      if user.simulations.any? && user.projects.empty?
        unless user.notifications.where(
          type: 'etape_suivante',
          created_at: 7.days.ago..Time.current
        ).exists?
          Notification.create_etape_suivante(
            user,
            "Créez votre premier projet pour organiser vos travaux et documents",
            "/projects/new"
          )
        end
      end

      # Si l'utilisateur a un projet mais pas de documents
      user.projects.each do |project|
        if project.documents.empty? && project.created_at < 3.days.ago
          unless user.notifications.where(
            type: 'etape_suivante',
            project: project,
            created_at: 5.days.ago..Time.current
          ).exists?
            Notification.create_etape_suivante(
              user,
              "Commencez à télécharger vos documents pour le projet #{project.name}",
              "/projects/#{project.id}/documents"
            )
          end
        end
      end
    end

    # Méthodes pour les notifications admin
    def send_legal_update(title, message, expires_days = 30)
      Notification.create_admin_notification(
        type: :admin_legal,
        title: title,
        message: message,
        category: :legal,
        priority: :haute,
        expires_at: expires_days.days.from_now
      )
    end

    def send_new_prime_announcement(prime, target_region = nil)
      users = target_region ? User.where(region: target_region) : User.all

      Notification.create_admin_notification(
        type: :admin_nouvelle_prime,
        title: "Nouvelle prime disponible !",
        message: "🎉 La prime #{prime.titre} est maintenant disponible en #{prime.region}. Vérifiez votre éligibilité !",
        category: :primes,
        priority: :normale,
        target_users: users,
        expires_at: 60.days.from_now
      )
    end

    def send_maintenance_notice(title, message, scheduled_date)
      Notification.create_admin_notification(
        type: :admin_maintenance,
        title: title,
        message: message,
        category: :maintenance,
        priority: :normale,
        expires_at: scheduled_date + 1.day
      )
    end

    def send_urgent_notice(title, message, target_users = nil)
      Notification.create_admin_notification(
        type: :admin_urgent,
        title: title,
        message: message,
        category: :systeme,
        priority: :critique,
        target_users: target_users,
        expires_at: 7.days.from_now
      )
    end
  end
end
