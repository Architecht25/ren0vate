class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         # Confirmable temporairement désactivé jusqu'à configuration complète SMTP

  # Auto-confirmer les utilisateurs à la création (solution temporaire)
  # Commenté car :confirmable est désactivé
  # after_create :auto_confirm_user

  # Enum pour les rôles
  enum :role, { user: 0, moderator: 1, admin: 2 }, default: :user

  # Validation pour s'assurer qu'il y ait toujours au moins un admin
  validate :ensure_at_least_one_admin, on: :update, if: :role_changed?

  has_many :simulations, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :projects, through: :properties, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

  belongs_to :last_active_simulation, class_name: "Simulation", optional: true

  # Validation pour la langue préférée
  validates :preferred_locale, inclusion: { in: %w[fr nl en] }, allow_blank: true

  # Méthodes pour les rôles
  def display_role
    case role
    when 'admin'
      'Administrateur'
    when 'moderator'
      'Modérateur'
    when 'user'
      'Utilisateur'
    else
      role.humanize
    end
  end

  def can_access_admin?
    admin? || moderator?
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  # Méthodes pour les notifications
  def unread_notifications_count
    notifications.unread.active.count
  end

  def has_unread_notifications?
    unread_notifications_count > 0
  end

  def mark_all_notifications_as_read!
    notifications.unread.update_all(read_at: Time.current)
  end

  # Méthodes pour la soumission et le paiement
  def can_submit?
    # Logique pour vérifier si l'utilisateur peut soumettre
    # À adapter selon votre modèle économique success fee
    has_active_subscription? || agreed_to_success_fee?
  end

  def has_active_subscription?
    # À implémenter avec votre système d'abonnement
    false
  end

  def agreed_to_success_fee?
    # À implémenter - vérifier si l'utilisateur a accepté les conditions success fee
    true # Pour l'instant, autoriser tous les utilisateurs
  end

  def submission_status
    if can_submit?
      'authorized'
    else
      'payment_required'
    end
  end

  # Calcul du revenu total du ménage pour les primes Bruxelles
  def household_income
    return nil unless revenu_demandeur.present?

    total = revenu_demandeur.to_i
    total += revenu_conjoint.to_i if revenu_conjoint.present?
    total
  end

  # Méthodes de compatibilité pour les services Bruxelles
  def marital_status
    # Mapper situation_familiale vers les valeurs attendues par le service
    case situation_familiale
    when 'marie', 'mariee', 'married'
      'married'
    when 'cohabitation', 'cohabiting'
      'cohabiting'
    when 'celibataire', 'single'
      'single'
    when 'divorce', 'divorced'
      'divorced'
    when 'veuf', 'veuve', 'widowed'
      'widowed'
    else
      'single'  # Valeur par défaut
    end
  end

  def children_count
    nombre_enfants || 0
  end

  def elderly_dependents
    # Pour le moment, retournons 0 car ce champ n'existe pas encore dans le schéma
    # TODO: Ajouter ce champ à la table users si nécessaire
    0
  end

  # === SUBSCRIPTION METHODS ===

  def current_subscription
    subscriptions.active.order(created_at: :desc).first
  end

  def subscription_tier
    current_subscription&.tier || 'freemium'
  end

  def subscription_tier_name
    current_subscription&.tier_name || 'Découverte'
  end

  def has_active_subscription?
    current_subscription&.active? || false
  end

  def subscription_days_remaining
    current_subscription&.current_period_days_remaining || 0
  end

  def can_access_feature?(feature)
    tier = subscription_tier

    case feature
    when :unlimited_properties
      %w[individual portfolio professional enterprise].include?(tier)
    when :ren0chat
      %w[individual portfolio professional enterprise].include?(tier)
    when :ren0bot
      %w[portfolio professional enterprise].include?(tier)
    when :decision_hub
      %w[portfolio professional enterprise].include?(tier)
    when :analytics
      %w[individual portfolio professional enterprise].include?(tier)
    when :priority_support
      %w[individual portfolio professional enterprise].include?(tier)
    when :api_access
      %w[portfolio professional enterprise].include?(tier)
    else
      false
    end
  end

  def property_limit
    case subscription_tier
    when 'freemium' then 1
    when 'individual' then 3
    when 'portfolio' then 10
    when 'professional', 'enterprise' then Float::INFINITY
    else 1
    end
  end

  def simulation_limit
    case subscription_tier
    when 'freemium' then 1
    else Float::INFINITY
    end
  end

  def ren0chat_monthly_limit
    case subscription_tier
    when 'individual' then 50
    when 'portfolio' then 150
    when 'professional', 'enterprise' then Float::INFINITY
    else 0
    end
  end

  private

  # Méthode de validation pour s'assurer qu'il y ait toujours au moins un admin
  def ensure_at_least_one_admin
    if role_was == 'admin' && !admin? && User.admin.count == 1
      errors.add(:role, "Il doit y avoir au moins un administrateur dans le système")
    end
  end

  # SOLUTION TEMPORAIRE : Auto-confirmer les utilisateurs
  # TODO: Retirer cette méthode une fois le problème d'email de confirmation résolu
  # Commenté car :confirmable est désactivé
  # def auto_confirm_user
  #   self.confirm unless self.confirmed?
  # end
end
