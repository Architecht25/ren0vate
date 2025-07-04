class Work < ApplicationRecord
  belongs_to :project
  belongs_to :prime

  validates :surface, :montant_estimé, presence: true
end
