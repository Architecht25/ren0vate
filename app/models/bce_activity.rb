class BceActivity < ApplicationRecord
  belongs_to :bce_enterprise, foreign_key: :entity_number, primary_key: :enterprise_number, optional: true
  
  scope :main_activities, -> { where(classification: 'MAIN') }
  
  def main_activity?
    classification == 'MAIN'
  end
end
