class Membership < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  ROLES = %w[member admin].freeze

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :organization_id }
end
