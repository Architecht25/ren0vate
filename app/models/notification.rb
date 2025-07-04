class Notification < ApplicationRecord
  belongs_to :user

  validates :message, :type, presence: true
end
