class Referral < ApplicationRecord
  belongs_to :user

  validates :email_ami, presence: true
end
