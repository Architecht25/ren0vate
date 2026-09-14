class IntelligenceReport < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze

  validates :week_of, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :completed, -> { where(status: 'completed') }
  scope :recent,    -> { order(created_at: :desc) }

  def self.current_week_key
    date = Date.today
    "#{date.year}-W#{date.cweek.to_s.rjust(2, '0')}"
  end

  def self.find_or_initialize_for_current_week
    find_or_initialize_by(week_of: current_week_key)
  end

  def week_label
    year, week = week_of.split('-W').map(&:to_i)
    date = Date.commercial(year, week, 1)
    "Semaine du #{date.strftime('%-d %B %Y')}"
  rescue
    week_of
  end

  def pending?    = status == 'pending'
  def processing? = status == 'processing'
  def completed?  = status == 'completed'
  def failed?     = status == 'failed'
end
