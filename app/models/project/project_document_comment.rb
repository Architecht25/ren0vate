class ProjectDocumentComment < ApplicationRecord
  belongs_to :project_document
  belongs_to :project_document_version, optional: true
  belongs_to :author, class_name: "User"

  validates :body, presence: true
end
