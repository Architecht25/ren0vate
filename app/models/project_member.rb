class ProjectMember < ApplicationRecord
  include ProjectPermissions

  belongs_to :project
  belongs_to :user

  ROLES   = %w[owner entrepreneur architect intermediary].freeze
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

  def accept!
    update!(
      status:           'active',
      accepted_at:      Time.current,
      invite_expires_at: nil
    )
  end

  private

  def generate_invite_token
    self.invite_token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiry
    self.invite_expires_at = 7.days.from_now
  end
end
