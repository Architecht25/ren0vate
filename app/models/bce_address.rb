class BceAddress < ApplicationRecord
  belongs_to :bce_enterprise, foreign_key: :entity_number, primary_key: :enterprise_number, optional: true
  
  scope :main_establishments, -> { where(type_of_address: 'BAET') }
  
  def main_establishment?
    type_of_address == 'BAET'
  end
end
