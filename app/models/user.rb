class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :confirmable

  # Chiffrement at-rest des données personnelles sensibles (RGPD A02)
  # Toutes les données en clair ont été rechiffrées le 04/09/2026 (voir
  # lib/tasks/encrypt_sensitive_data.rake) — plus de support_unencrypted_data
  # ici, on retombe sur config.active_record.encryption.support_unencrypted_data
  # (piloté par AR_ENCRYPTION_SUPPORT_UNENCRYPTED, déjà à false sur Heroku).
  encrypts :national_number
  encrypts :iban

  # Ces deux champs peuvent contenir une valeur chiffrée avec une clé qui n'est plus
  # la clé active de l'environnement courant (ex. donnée importée depuis un autre
  # environnement sans ses clés AR_ENCRYPTION_*). Sans ce garde-fou, le simple fait
  # d'afficher le formulaire de profil lève ActiveRecord::Encryption::Errors::Decryption
  # et fait planter la page — on renvoie nil plutôt que de laisser planter la vue.
  def national_number
    super
  rescue ActiveRecord::Encryption::Errors::Decryption
    nil
  end

  def iban
    super
  rescue ActiveRecord::Encryption::Errors::Decryption
    nil
  end

  # true si une valeur est présente en base mais illisible avec la clé de chiffrement
  # actuelle (à distinguer d'un champ simplement vide) — utile pour prévenir l'utilisateur
  # plutôt que de lui laisser croire que le champ n'a jamais été rempli.
  def national_number_undecryptable?
    read_attribute_before_type_cast(:national_number).present? && national_number.nil?
  end

  def iban_undecryptable?
    read_attribute_before_type_cast(:iban).present? && iban.nil?
  end

  # À appeler avant tout update du profil : le simple fait de sauvegarder (même sans
  # toucher à ces deux champs) déclenche le dirty-tracking d'ActiveRecord, qui tente de
  # déchiffrer l'ANCIENNE valeur en base pour la comparer à la nouvelle — et plante avec
  # ActiveRecord::Encryption::Errors::Decryption si cette ancienne valeur est illisible
  # avec la clé actuelle. On la purge directement en base (update_column, hors cycle de
  # dirty-tracking) pour repartir d'une base propre avant l'update normal.
  def repair_undecryptable_encrypted_fields!
    return if new_record?
    %i[national_number iban].each do |attr|
      update_column(attr, nil) if send("#{attr}_undecryptable?")
    end
  end

  # Enum pour les rôles
  enum :role, { user: 0, moderator: 1, admin: 2 }, default: :user

  # Enum pour le profil utilisateur (tunnel onboarding)
  enum :user_profile, { proprietaire: 0, architecte: 1, entrepreneur: 2, intermediaire: 3 }, default: :proprietaire

  # Validation pour s'assurer qu'il y ait toujours au moins un admin
  validate :ensure_at_least_one_admin, on: :update, if: :role_changed?

  has_many :simulations, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :projects, through: :properties, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_many :pret_wallonie_dossiers, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :aer_donnees, dependent: :destroy
  has_many :rib_donnees, dependent: :destroy
  has_many :peb_donnees, dependent: :destroy
  has_many :support_tickets, dependent: :destroy
  has_many :nps_responses, dependent: :destroy
  has_many :page_visits, dependent: :delete_all

  # Collaboration — projets dont l'utilisateur est membre (pro invité)
  has_many :project_members, dependent: :destroy
  has_many :member_projects, through: :project_members, source: :project

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

  # Returns true if the user has no owned properties and is actively
  # a member (entrepreneur or architect) on at least one project,
  # OR is a registered professional (architect/entrepreneur) awaiting their first client.
  # These users get a simplified "guest pro" sidebar instead of the owner sidebar.
  # Vrai si l'utilisateur est un professionnel, que ce soit via professional_type
  # (inscription directe) ou via des ProjectMember actifs (invitation sur projet).
  def professional?
    professional_type.present? || project_members.active.pros.exists?
  end

  def professional_guest?
    return true if professional_type.present? && properties.none?
    properties.none? && project_members.active.pros.any?
  end

  def architect?
    return true if professional_type == 'architect'
    professional_type.blank? && project_members.active.exists?(role: 'architect')
  end

  def professional_entrepreneur?
    return true if professional_type == 'entrepreneur'
    professional_type.blank? && project_members.active.exists?(role: 'entrepreneur')
  end

  def intermediary?
    return true if professional_type == 'intermediary'
    professional_type.blank? && project_members.active.exists?(role: 'intermediary')
  end

  # Retourne un label lisible des rôles pro actifs (via professional_type OU ProjectMember).
  # Exemples : "Entrepreneur", "Architecte", "Entrepreneur · Architecte"
  def pro_roles_label
    if professional_type.present?
      case professional_type
      when 'architect'    then 'Architecte'
      when 'entrepreneur' then 'Entrepreneur'
      when 'intermediary' then 'Intermédiaire'
      end
    else
      roles = project_members.active.where(role: %w[entrepreneur architect intermediary]).pluck(:role).uniq
      roles.map { |r|
        case r
        when 'architect'    then 'Architecte'
        when 'entrepreneur' then 'Entrepreneur'
        when 'intermediary' then 'Intermédiaire'
        end
      }.join(' · ')
    end
  end

  def onboarding_done?
    onboarding_completed_at.present?
  end

  # Génère (ou retourne) le token de parrainage pour inviter des clients
  def referral_token!
    return referral_token if referral_token.present?
    update_column(:referral_token, SecureRandom.urlsafe_base64(16))
    referral_token
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
      %w[individual portfolio premium_mixed professional enterprise].include?(tier)
    when :ren0chat
      %w[individual portfolio premium_mixed professional enterprise].include?(tier)
    when :ren0bot
      %w[portfolio premium_mixed professional enterprise].include?(tier)
    when :decision_hub
      %w[portfolio premium_mixed professional enterprise].include?(tier)
    when :analytics
      %w[individual portfolio premium_mixed professional enterprise].include?(tier)
    when :priority_support
      %w[individual portfolio premium_mixed professional enterprise].include?(tier)
    when :api_access
      %w[premium_mixed portfolio professional enterprise].include?(tier)
    when :suivi_chantier
      %w[portfolio premium_mixed professional enterprise].include?(tier)
    when :comparateur_entrepreneurs
      %w[individual portfolio premium_mixed professional enterprise].include?(tier)
    when :dossier_documentaire
      %w[individual portfolio premium_mixed professional enterprise].include?(tier)
    when :export_comptable
      %w[enterprise].include?(tier)
    when :rapport_pdf
      %w[professional enterprise].include?(tier)
    when :gestion_locative
      %w[portfolio premium_mixed professional enterprise].include?(tier)
    else
      false
    end
  end

  def property_limit
    case subscription_tier
    when 'freemium' then 1
    when 'individual' then 3
    when 'portfolio' then 10
    when 'premium_mixed', 'professional', 'enterprise' then Float::INFINITY
    else 1
    end
  end

  def project_limit
    case subscription_tier
    when 'freemium' then 1
    else Float::INFINITY
    end
  end

  # Nombre max de clients actifs pour les profils intermédiaire/architecte/entrepreneur
  def client_limit
    case subscription_tier
    when 'freemium'    then 3
    when 'individual'  then 3
    when 'professional', 'portfolio', 'premium_mixed' then 20
    when 'enterprise'  then Float::INFINITY
    else 3
    end
  end

  def at_client_limit?
    return false if client_limit == Float::INFINITY
    project_members.active.count >= client_limit
  end

  def simulation_limit
    case subscription_tier
    when 'freemium' then 1
    else Float::INFINITY
    end
  end

  def ren0chat_monthly_limit
    return Float::INFINITY if professional?
    case subscription_tier
    when 'individual' then 50
    when 'portfolio' then 150
    when 'premium_mixed', 'professional', 'enterprise' then Float::INFINITY
    else 5  # freemium — 5 messages/mois pour découvrir la valeur
    end
  end

  private

  # Méthode de validation pour s'assurer qu'il y ait toujours au moins un admin
  def ensure_at_least_one_admin
    if role_was == 'admin' && !admin? && User.admin.count == 1
      errors.add(:role, "Il doit y avoir au moins un administrateur dans le système")
    end
  end

end
