class NpsResponse < ApplicationRecord
  belongs_to :user

  TRIGGERS = %w[day14 day30 after_project].freeze

  validates :score, presence: true, inclusion: { in: 0..10 }
  validates :trigger, inclusion: { in: TRIGGERS }

  scope :recent, -> { order(created_at: :desc) }

  def promoter?
    score >= 9
  end

  def passive?
    score.in?(7..8)
  end

  def detractor?
    score <= 6
  end

  def self.nps_score
    return nil if count < 5

    promoters  = where('score >= 9').count.to_f
    detractors = where('score <= 6').count.to_f
    total      = count.to_f

    ((promoters / total - detractors / total) * 100).round
  end
end
