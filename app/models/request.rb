class Request < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :project
  belongs_to :simulation
end
