class ProjectMember < ApplicationRecord
  include ProjectPermissions

  belongs_to :project
  belongs_to :user

  has_many :project_member_lots, dependent: :destroy
  has_many :lots, through: :project_member_lots

  # "observer" — V2 : rôle lecture seule (banque, comptable, auditeur,
  # conseiller — cahier des charges V2 §3), absent de la V1. Les rôles
  # existants (owner/entrepreneur/architect/intermediary) sont conservés tels
  # quels : "intermediary" couvre un usage V1 différent (parrainage pro) non
  # tranché avec le rôle "Observateur" du cahier des charges — voir
  # docs/QUESTIONS_OUVERTES.md.
  ROLES   = %w[owner entrepreneur architect intermediary observer].freeze
  STATUSES = %w[pending active].freeze

  validates :role,   inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :project_id, message: "est déjà membre de ce projet" }

  before_create :generate_invite_token
  before_create :set_expiry

  scope :active,    -> { where(status: 'active') }
  scope :pending,   -> { where(status: 'pending') }
  scope :owners,    -> { where(role: 'owner') }
  scope :pros,      -> { where(role: %w[entrepreneur architect intermediary]) }

  def pending?
    status == 'pending'
  end

  def active?
    status == 'active'
  end

  def expired?
    invite_expires_at.present? && invite_expires_at < Time.current
  end

  # Absence de ligne project_member_lots == accès à tous les lots du projet
  # (cahier des charges V2 §3 : le périmètre de lots est une restriction
  # optionnelle, pas une liste à toujours remplir).
  def scoped_to_all_lots?
    lots.none?
  end

  def can_access_lot?(lot)
    scoped_to_all_lots? || lots.include?(lot)
  end

  def accept!
    update!(
      status:           'active',
      accepted_at:      Time.current,
      invite_expires_at: nil
    )
    # L'acceptation d'une invitation vaut onboarding terminé : sans ce flag,
    # after_sign_in_path_for renvoie le pro déjà actif vers l'onboarding à sa session suivante.
    user.update_column(:onboarding_completed_at, Time.current) if user.onboarding_completed_at.blank?
  end

  private

  def generate_invite_token
    self.invite_token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiry
    self.invite_expires_at = 7.days.from_now
  end
end
