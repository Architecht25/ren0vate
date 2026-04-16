class Reserve < ApplicationRecord
  belongs_to :project

  STATUTS = %w[ouverte en_cours levee].freeze

  validates :description, presence: true
  validates :statut, inclusion: { in: STATUTS }

  scope :ouvertes,  -> { where(statut: 'ouverte') }
  scope :en_cours,  -> { where(statut: 'en_cours') }
  scope :levees,    -> { where(statut: 'levee') }
  scope :actives,   -> { where(statut: %w[ouverte en_cours]) }

  def levee?   = statut == 'levee'
  def ouverte? = statut == 'ouverte'
  def en_cours? = statut == 'en_cours'

  def statut_label
    { 'ouverte' => 'Ouverte', 'en_cours' => 'En cours', 'levee' => 'Levée' }[statut] || statut
  end

  def statut_color
    { 'ouverte' => 'danger', 'en_cours' => 'warning', 'levee' => 'success' }[statut] || 'secondary'
  end

  def statut_icon
    { 'ouverte' => 'bi-exclamation-circle', 'en_cours' => 'bi-clock', 'levee' => 'bi-check-circle-fill' }[statut] || 'bi-circle'
  end
end
