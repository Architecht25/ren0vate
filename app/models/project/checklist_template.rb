class ChecklistTemplate < ApplicationRecord
  has_many :checklist_items, -> { order(:position) }, dependent: :destroy
  has_many :project_checklists, dependent: :destroy

  PHASES = %w[gros_oeuvre second_oeuvre finitions reception].freeze

  validates :name, presence: true
  validates :phase, inclusion: { in: PHASES }

  scope :ordered, -> { order(:position, :name) }

  def phase_label
    {
      'gros_oeuvre'   => 'Gros œuvre',
      'second_oeuvre' => 'Second œuvre',
      'finitions'     => 'Finitions',
      'reception'     => 'Réception'
    }[phase] || phase.humanize
  end

  def phase_icon
    {
      'gros_oeuvre'   => 'bi-bricks',
      'second_oeuvre' => 'bi-tools',
      'finitions'     => 'bi-brush',
      'reception'     => 'bi-clipboard2-check'
    }[phase] || 'bi-list-check'
  end

  def phase_color
    {
      'gros_oeuvre'   => 'danger',
      'second_oeuvre' => 'warning',
      'finitions'     => 'primary',
      'reception'     => 'success'
    }[phase] || 'secondary'
  end
end
