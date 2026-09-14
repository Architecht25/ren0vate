class ProjectNote < ApplicationRecord
  belongs_to :project

  validates :content, presence: true, length: { maximum: 2000 }

  default_scope { order(created_at: :desc) }
end
