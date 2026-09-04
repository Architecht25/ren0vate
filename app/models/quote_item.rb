class QuoteItem < ApplicationRecord
  belongs_to :quote

  validates :work_type_key, :quantity, :unit, presence: true
  validates :quantity, numericality: { greater_than: 0 }

  def work_type
    WorkType.find(work_type_key, region: quote.property.region)
  end
end
