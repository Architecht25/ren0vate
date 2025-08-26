class BceEnterprise < ApplicationRecord
  has_many :bce_denominations, foreign_key: :entity_number, primary_key: :enterprise_number
  has_many :bce_addresses, foreign_key: :entity_number, primary_key: :enterprise_number
  has_many :bce_activities, foreign_key: :entity_number, primary_key: :enterprise_number
  
  scope :active, -> { where(status_code: 'AC') }
  scope :inactive, -> { where.not(status_code: 'AC') }
  
  def self.find_by_number(number)
    normalized = number.to_s.gsub(/[\.\s\-]/, '')
    where("REPLACE(REPLACE(REPLACE(enterprise_number, '.', ''), ' ', ''), '-', '') = ?", normalized).first
  end
  
  def primary_denomination
    bce_denominations.where(type_of_denomination: '001').first&.denomination ||
      bce_denominations.first&.denomination
  end
  
  def formatted_status
    case status_code
    when 'AC'
      'Actif'
    when 'IN'
      'Inactif'
    else
      status_code
    end
  end
end
