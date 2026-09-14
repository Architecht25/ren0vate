class ChecklistItem < ApplicationRecord
  belongs_to :checklist_template

  validates :description, presence: true

  scope :ordered, -> { order(:position, :id) }
end
