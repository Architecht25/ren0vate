class RequestProgress < ApplicationRecord
  belongs_to :request
  belongs_to :prime

  validates :step, :pourcentage, presence: true
end
