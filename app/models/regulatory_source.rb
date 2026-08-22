# Pages officielles de référence (wallonie.be, vlaanderen.be...) surveillées pour
# détecter un changement de réglementation primes/prêts avant que ça ne se voie
# dans une simulation erronée. Voir RegulatoryWatchJob (mensuel) et
# RegulatoryWatchService (fetch + diff de contenu).
class RegulatorySource < ApplicationRecord
  validates :url, presence: true, uniqueness: true
  validates :label, presence: true

  scope :active, -> { where(active: true) }

  REGIONS = %w[wallonie flandre bruxelles belgique].freeze
  validates :region, inclusion: { in: REGIONS }, allow_nil: true

  def checked_recently?
    last_checked_at.present? && last_checked_at > 25.days.ago
  end

  def region_label
    { "wallonie" => "Wallonie", "flandre" => "Flandre", "bruxelles" => "Bruxelles", "belgique" => "Belgique" }[region] || region
  end
end
