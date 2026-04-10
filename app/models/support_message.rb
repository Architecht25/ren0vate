class SupportMessage < ApplicationRecord
  belongs_to :support_ticket
  belongs_to :user

  validates :body, presence: true, length: { minimum: 5, maximum: 5000 }

  after_create :update_ticket_on_admin_reply

  private

  def update_ticket_on_admin_reply
    if is_admin_reply?
      support_ticket.update!(
        status: 'in_progress',
        responded_at: support_ticket.responded_at || created_at
      )
    end
  end
end
