class ChantierAnalyse < ApplicationRecord
  belongs_to :project

  scope :recent_first, -> { order(analysed_at: :desc) }
end
