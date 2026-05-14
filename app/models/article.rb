class Article < ApplicationRecord
  CATEGORIES = {
    "conseils"   => "Conseils pratiques",
    "primes"     => "Primes & aides",
    "permis"     => "Permis & réglementation",
    "pros"       => "Pour les professionnels",
    "actualites" => "Actualités"
  }.freeze

  validates :title,    presence: true
  validates :slug,     presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :excerpt,  presence: true
  validates :content,  presence: true
  validates :category, inclusion: { in: CATEGORIES.keys }

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  before_validation :estimate_reading_time, if: -> { content_changed? }

  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current).order(published_at: :desc) }
  scope :drafts,    -> { where(published_at: nil) }
  scope :by_category, ->(cat) { where(category: cat) }

  def published?
    published_at.present? && published_at <= Time.current
  end

  def category_label
    CATEGORIES[category]
  end

  private

  def generate_slug
    base = title.parameterize
    candidate = base
    n = 1
    while Article.where(slug: candidate).where.not(id: id).exists?
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.slug = candidate
  end

  def estimate_reading_time
    words = content.to_s.split.size
    self.reading_time_minutes = [(words / 200.0).ceil, 1].max
  end
end
