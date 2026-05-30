class MarketingWeek < ApplicationRecord
  STATUSES = %w[draft reviewed published].freeze

  belongs_to :article, optional: true

  validates :week_of, presence: true, uniqueness: true
  validates :status,  inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
  scope :drafts, -> { where(status: 'draft') }

  def week_label
    year, week = week_of.split('-W').map(&:to_i)
    date = Date.commercial(year, week, 1)
    "Semaine du #{date.strftime('%-d %B %Y')}"
  rescue
    week_of
  end

  def social_posts_count
    [linkedin_post, instagram_post, facebook_post].count(&:present?)
  end

  def draft?     = status == 'draft'
  def reviewed?  = status == 'reviewed'
  def published? = status == 'published'
end
