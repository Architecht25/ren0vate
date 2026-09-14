class VeilleArticle < ApplicationRecord
  SOURCES = [ "L'Echo", "Trends", "Tendances", "De Tijd", "Le Soir", "La Libre", "RTBF", "Autre" ].freeze
  REGIONS = %w[belgique wallonie flandre bruxelles].freeze
  THEMES  = %w[renovation peb primes financement marche-immobilier reglementation bailleurs audit].freeze

  validates :titre, presence: true
  validates :contenu, presence: true
  validates :source_date, presence: true
  validates :region, inclusion: { in: REGIONS }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :recent, -> { order(source_date: :desc) }
  scope :for_bot, -> { active.recent.limit(5) }

  def themes_list
    return [] if themes.blank?
    themes.split(",").map(&:strip).reject(&:blank?)
  end

  def themes_list=(arr)
    self.themes = Array(arr).reject(&:blank?).join(", ")
  end

  def region_label
    { "belgique" => "Belgique", "wallonie" => "Wallonie", "flandre" => "Flandre", "bruxelles" => "Bruxelles" }[region] || region&.capitalize
  end
end
