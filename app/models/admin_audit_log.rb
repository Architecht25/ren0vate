class AdminAuditLog < ApplicationRecord
  belongs_to :admin, class_name: "User", foreign_key: :admin_id
  belongs_to :target_user, class_name: "User", foreign_key: :target_user_id, optional: true

  ACTIONS = %w[impersonate stop_impersonating user_update user_destroy role_change].freeze

  validates :action, inclusion: { in: ACTIONS }

  def self.log(admin:, action:, target_user: nil, request: nil, metadata: {})
    create!(
      admin: admin,
      target_user: target_user,
      action: action,
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent&.truncate(255),
      metadata: metadata.to_json
    )
  end
end
