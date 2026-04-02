class Notification < ApplicationRecord
  self.inheritance_column = nil  # Désactiver l'héritage STI pour la colonne 'type'

  belongs_to :user
  belongs_to :property, optional: true
  belongs_to :project, optional: true
  belongs_to :simulation, optional: true

  validates :message, :type, :title, presence: true
  validates :category, presence: true

  # Callbacks
  after_initialize :set_defaults, if: :new_record?
  after_create_commit :send_email_notification

  def set_defaults
    self.priority ||= :normale
  end

  # Énumérations
  enum :type, {
    # Notifications automatiques système
    dossier_incomplet: 'dossier_incomplet',
    facture_manquante: 'facture_manquante',
    deadline_proche: 'deadline_proche',
    conseil_optimisation: 'conseil_optimisation',
    etape_suivante: 'etape_suivante',
    document_requis: 'document_requis',
    simulation_expiration: 'simulation_expiration',
    prime_eligible: 'prime_eligible',
    verification_requise: 'verification_requise',
    suivi_projet: 'suivi_projet',

    # Notifications admin
    admin_info: 'admin_info',
    admin_legal: 'admin_legal',
    admin_maintenance: 'admin_maintenance',
    admin_nouvelle_prime: 'admin_nouvelle_prime',
    admin_urgent: 'admin_urgent'
  }

  enum :category, {
    documents: 'documents',
    primes: 'primes',
    projets: 'projets',
    simulations: 'simulations',
    systeme: 'systeme',
    legal: 'legal',
    maintenance: 'maintenance',
    aide: 'aide',
    rappel: 'rappel',
    nouveaute: 'nouveaute',
    urgent: 'urgent'
  }

  enum :priority, {
    basse: 0,
    normale: 1,
    haute: 2,
    critique: 3,
    urgente: 4
  }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }
  scope :read_notifications, -> { where.not(read_at: nil) }
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :by_priority, -> { order(priority: :desc, created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  # Méthodes d'instance
  def read?
    read_at.present?
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  def priority_color
    case priority
    when 'critique' then 'danger'
    when 'haute' then 'warning'
    when 'normale' then 'primary'
    else 'secondary'
    end
  end

  def type_icon
    case type
    when 'dossier_incomplet', 'document_requis' then 'bi-file-earmark-x'
    when 'facture_manquante' then 'bi-receipt'
    when 'deadline_proche' then 'bi-clock'
    when 'conseil_optimisation' then 'bi-lightbulb'
    when 'etape_suivante' then 'bi-arrow-right-circle'
    when 'simulation_expiration' then 'bi-hourglass-split'
    when 'prime_eligible' then 'bi-gift'
    when 'verification_requise' then 'bi-shield-check'
    when 'suivi_projet' then 'bi-kanban'
    when 'admin_info' then 'bi-info-circle'
    when 'admin_legal' then 'bi-book'
    when 'admin_maintenance' then 'bi-tools'
    when 'admin_nouvelle_prime' then 'bi-star'
    when 'admin_urgent' then 'bi-exclamation-triangle'
    else 'bi-bell'
    end
  end

  # Méthodes de classe pour les notifications automatiques
  class << self
    # 1. Dossier incomplet - Documents manquants
    def create_dossier_incomplet(user, property, missing_docs)
      create!(
        user: user,
        property: property,
        type: :dossier_incomplet,
        category: :documents,
        title: "Dossier incomplet",
        message: "Il manque #{missing_docs.count} document(s) pour finaliser votre dossier : #{missing_docs.join(', ')}",
        action_url: "/properties/#{property.id}/documents",
        priority: :haute,
        expires_at: 30.days.from_now
      )
    end

    # 2. Facture manquante spécifique
    def create_facture_manquante(user, project, travaux_type)
      create!(
        user: user,
        project: project,
        type: :facture_manquante,
        category: :documents,
        title: "Facture manquante",
        message: "N'oubliez pas de télécharger la facture pour vos travaux de #{travaux_type}. C'est obligatoire pour votre demande de prime.",
        action_url: "/projects/#{project.id}/documents",
        priority: :haute,
        expires_at: 15.days.from_now
      )
    end

    # 3. Deadline proche
    def create_deadline_proche(user, deadline_date, context)
      create!(
        user: user,
        type: :deadline_proche,
        category: :systeme,
        title: "Échéance proche",
        message: "Attention ! Vous avez une échéance le #{I18n.l(deadline_date, format: :long)} pour #{context}. Il vous reste #{(deadline_date.to_date - Date.current).to_i} jours.",
        priority: :critique,
        expires_at: deadline_date
      )
    end

    # 4. Conseil d'optimisation
    def create_conseil_optimisation(user, simulation, conseil)
      create!(
        user: user,
        simulation: simulation,
        type: :conseil_optimisation,
        category: :primes,
        title: "Conseil d'optimisation",
        message: "💡 #{conseil}",
        action_url: "/simulations/#{simulation.id}",
        priority: :normale,
        expires_at: 60.days.from_now
      )
    end

    # 5. Étape suivante suggérée
    def create_etape_suivante(user, next_step, context_url = nil)
      create!(
        user: user,
        type: :etape_suivante,
        category: :projets,
        title: "Prochaine étape",
        message: "🚀 #{next_step}",
        action_url: context_url,
        priority: :normale,
        expires_at: 45.days.from_now
      )
    end

    # 6. Document requis pour prime
    def create_document_requis(user, prime, document_type)
      create!(
        user: user,
        type: :document_requis,
        category: :documents,
        title: "Document requis",
        message: "Pour votre prime #{prime.titre}, vous devez fournir : #{document_type}",
        action_url: "/documents?prime_id=#{prime.id}",
        priority: :haute,
        expires_at: 20.days.from_now
      )
    end

    # 7. Simulation va expirer
    def create_simulation_expiration(user, simulation, days_left)
      create!(
        user: user,
        simulation: simulation,
        type: :simulation_expiration,
        category: :simulations,
        title: "Simulation expire bientôt",
        message: "Votre simulation va expirer dans #{days_left} jours. Pensez à la finaliser ou à créer un projet.",
        action_url: "/simulations/#{simulation.id}",
        priority: :normale,
        expires_at: days_left.days.from_now
      )
    end

    # 8. Nouvelle prime éligible
    def create_prime_eligible(user, prime, reason)
      create!(
        user: user,
        type: :prime_eligible,
        category: :primes,
        title: "Nouvelle prime éligible !",
        message: "🎯 Vous êtes éligible à la prime #{prime.titre}. #{reason}",
        action_url: "/simulations/new?prime_id=#{prime.id}",
        priority: :normale,
        expires_at: 90.days.from_now
      )
    end

    # 9. Vérification requise
    def create_verification_requise(user, element, reason)
      create!(
        user: user,
        type: :verification_requise,
        category: :systeme,
        title: "Vérification requise",
        message: "⚠️ Veuillez vérifier #{element}. #{reason}",
        priority: :haute,
        expires_at: 10.days.from_now
      )
    end

    # 10. Suivi de projet
    def create_suivi_projet(user, project, status_message)
      create!(
        user: user,
        project: project,
        type: :suivi_projet,
        category: :projets,
        title: "Mise à jour projet",
        message: "📋 #{status_message}",
        action_url: "/projects/#{project.id}",
        priority: :normale,
        expires_at: 30.days.from_now
      )
    end

    # Méthodes pour notifications admin
    def create_admin_notification(type:, title:, message:, category: :systeme, priority: :normale, target_users: nil, expires_at: nil)
      users = target_users || User.all

      users.find_each do |user|
        create!(
          user: user,
          type: type,
          category: category,
          title: title,
          message: message,
          priority: priority,
          expires_at: expires_at
        )
      end
    end
  end

  private

  def send_email_notification
    NotificationMailer.alert(self).deliver_later
  end
end
