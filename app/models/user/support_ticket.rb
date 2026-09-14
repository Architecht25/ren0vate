class SupportTicket < ApplicationRecord
  belongs_to :user
  has_many :support_messages, dependent: :destroy

  STATUSES    = %w[open in_progress resolved closed].freeze
  PRIORITIES  = %w[normal urgent].freeze
  CATEGORIES  = %w[general technique facturation prime compte autre].freeze

  CATEGORY_LABELS = {
    'general'     => 'Question générale',
    'technique'   => 'Problème technique',
    'facturation' => 'Facturation / abonnement',
    'prime'       => 'Primes & subventions',
    'compte'      => 'Mon compte',
    'autre'       => 'Autre'
  }.freeze

  validates :subject,  presence: true, length: { minimum: 5, maximum: 200 }
  validates :status,   inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :category, inclusion: { in: CATEGORIES }

  scope :open_tickets,     -> { where(status: %w[open in_progress]) }
  scope :recent,           -> { order(created_at: :desc) }
  scope :waiting_response, -> { where(status: 'open').where(responded_at: nil) }
  scope :overdue,          -> { waiting_response.where('created_at < ?', 22.hours.ago) }

  def status_label
    case status
    when 'open'        then 'Ouvert'
    when 'in_progress' then 'En cours'
    when 'resolved'    then 'Résolu'
    when 'closed'      then 'Fermé'
    else status.humanize
    end
  end

  def status_color
    case status
    when 'open'        then 'warning'
    when 'in_progress' then 'primary'
    when 'resolved'    then 'success'
    when 'closed'      then 'secondary'
    end
  end

  def category_label
    CATEGORY_LABELS[category] || category.humanize
  end

  def hours_since_creation
    ((Time.current - created_at) / 1.hour).round
  end

  def within_sla?
    responded_at.present? ? true : hours_since_creation < 24
  end

  def sla_remaining_hours
    [24 - hours_since_creation, 0].max
  end
end
