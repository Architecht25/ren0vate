class PageVisit < ApplicationRecord
  belongs_to :user, optional: true  # null pour les visiteurs anonymes

  validates :page_name, presence: true
  validates :visited_at, presence: true

  scope :anonymous, -> { where(user_id: nil) }
  scope :authenticated, -> { where.not(user_id: nil) }
  scope :by_region, ->(region) { where(region: region) }
  scope :by_page_type, ->(type) { where(page_type: type) }
  scope :recent, ->(days = 30) { where(visited_at: days.days.ago..Time.current) }
  scope :today, -> { where(visited_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :this_week, -> { where(visited_at: Time.current.beginning_of_week..Time.current.end_of_week) }
  scope :this_month, -> { where(visited_at: Time.current.beginning_of_month..Time.current.end_of_month) }

  # Méthodes de classe pour les statistiques
  def self.popular_pages(limit = 10)
    group(:page_name)
      .order('count_page_name DESC')
      .limit(limit)
      .count(:page_name)
  end

  def self.daily_visits(days = 7)
    recent(days)
      .group("DATE(visited_at)")
      .order('DATE(visited_at)')
      .count
  end

  def self.visits_by_region
    group(:region)
      .count
  end

  def self.simulation_activity
    where(page_type: ['simulation', 'bruxelles_particuliers', 'bruxelles_entreprises', 'wallonie_particuliers', 'flandre_particuliers'])
      .group(:page_name)
      .count
  end

  def self.anonymous_vs_authenticated
    {
      anonymous: anonymous.count,
      authenticated: authenticated.count
    }
  end

  # Méthode pour créer une visite
  def self.track_visit(page_name:, request:, user: nil, region: nil, page_type: nil)
    create!(
      page_name: page_name,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referrer: request.referer,
      visited_at: Time.current,
      user: user,
      session_id: request.session.id,
      region: region,
      page_type: page_type
    )
  rescue => e
    Rails.logger.error "Erreur tracking PageVisit: #{e.message}"
    nil
  end
end
