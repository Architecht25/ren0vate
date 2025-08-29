class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

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

  private

  # Méthode de validation pour s'assurer qu'il y ait toujours au moins un admin
  def ensure_at_least_one_admin
    if role_was == 'admin' && !admin? && User.admin.count == 1
      errors.add(:role, "Il doit y avoir au moins un administrateur dans le système")
    end
  end
end
