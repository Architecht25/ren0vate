class BceDenomination < ApplicationRecord
  belongs_to :bce_enterprise, foreign_key: :entity_number, primary_key: :enterprise_number, optional: true
  
  scope :official, -> { where(type_of_denomination: '001') }
  
  def official?
    type_of_denomination == '001'
  end
end
