class RentPayment < ApplicationRecord
  belongs_to :lease

  enum :status, {
    pending: 'pending',
    paid: 'paid',
    late: 'late',
    partial: 'partial'
  }, prefix: false

  validates :due_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }

  scope :overdue, -> { where(status: %w[pending late]).where('due_date < ?', Date.current) }
  scope :this_month, -> { where(due_date: Date.current.beginning_of_month..Date.current.end_of_month) }

  before_save :auto_set_late_status

  def statut_label
    case status
    when 'pending' then 'En attente'
    when 'paid' then 'Payé'
    when 'late' then 'En retard'
    when 'partial' then 'Partiel'
    end
  end

  def statut_badge_class
    case status
    when 'pending' then 'warning'
    when 'paid' then 'success'
    when 'late' then 'danger'
    when 'partial' then 'info'
    end
  end

  private

  def auto_set_late_status
    if status == 'pending' && due_date.present? && due_date < Date.current
      self.status = 'late'
    end
  end
end
