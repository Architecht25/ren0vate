class PebDonnee < ApplicationRecord
  belongs_to :property, optional: true
  belongs_to :document, optional: true
  belongs_to :user

  LABELS_VALIDES = %w[A++ A+ A B C D E F G].freeze
  REGIONS_VALIDES = %w[wallonie flandre bruxelles].freeze

  validates :region, inclusion: { in: REGIONS_VALIDES }, allow_blank: true
  validates :label_peb, inclusion: { in: LABELS_VALIDES }, allow_blank: true

  scope :recents, -> { order(created_at: :desc) }
  scope :valides, -> { where(extraction_complete: true) }

  # Label PEB formaté avec couleur Bootstrap
  COULEURS_LABEL = {
    'A++' => 'success', 'A+' => 'success', 'A' => 'success',
    'B'   => 'info',
    'C'   => 'primary',
    'D'   => 'warning',
    'E'   => 'warning',
    'F'   => 'danger',
    'G'   => 'danger'
  }.freeze

  def couleur_bootstrap
    COULEURS_LABEL.fetch(label_peb&.upcase, 'secondary')
  end

  def score_ep_formate
    return nil unless score_ep
    "#{score_ep.to_i} kWh/(m².an)"
  end

  def perime?
    return false unless date_validite
    date_validite < Date.today
  end
end
