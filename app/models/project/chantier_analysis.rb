class ChantierAnalysis < ApplicationRecord
  belongs_to :project

  scope :recent_first, -> { order(analysed_at: :desc) }

  def observations_list
    return [] if observations.blank?
    observations.split("\n").map(&:strip).reject(&:blank?)
  end

  def alertes_list
    return [] if alertes.blank?
    alertes.split("\n").map(&:strip).reject(&:blank?)
  end

  def prochaines_etapes_list
    return [] if prochaines_etapes.blank?
    prochaines_etapes.split("\n").map(&:strip).reject(&:blank?)
  end
end
