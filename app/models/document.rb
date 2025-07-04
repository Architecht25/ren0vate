class Document < ApplicationRecord
  belongs_to :user
  belongs_to :property, optional: true
  belongs_to :request, optional: true
  belongs_to :project, optional: true
  belongs_to :simulation, optional: true

  validates :file_url, :type_document, presence: true
end
