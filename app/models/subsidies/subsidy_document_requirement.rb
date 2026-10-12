class SubsidyDocumentRequirement < ApplicationRecord
  belongs_to :subsidy_rule

  validates :document_type, presence: true
end
