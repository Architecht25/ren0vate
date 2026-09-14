class Quote < ApplicationRecord
  belongs_to :property
  belongs_to :user
  has_many :quote_items, dependent: :destroy

  STATUSES = %w[draft sent accepted].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def items_with_work_type
    quote_items.map do |item|
      { item: item, work_type: WorkType.find(item.work_type_key, region: property.region) }
    end
  end
end
