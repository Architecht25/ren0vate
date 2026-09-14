class Tenant < ApplicationRecord
  belongs_to :property
  belongs_to :user
  has_many :leases, dependent: :destroy

  encrypts :national_number_ciphertext

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def active_lease
    leases.where(status: 'actif').order(start_date: :desc).first
  end
end
