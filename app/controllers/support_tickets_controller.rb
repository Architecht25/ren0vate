class SupportTicketsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_paid_plan!
  before_action :set_ticket, only: [:show, :reply, :close]

  def index
    @tickets = current_user.support_tickets.recent
  end

  def new
    @ticket = SupportTicket.new
  end

  def create
    @ticket = current_user.support_tickets.build(ticket_params)
    @ticket.priority = 'normal'

    if @ticket.save
      # Premier message = corps de la demande
      @ticket.support_messages.create!(
        user: current_user,
        body: params[:support_ticket][:initial_message],
        is_admin_reply: false
      )
      SupportMailer.ticket_received(current_user, @ticket).deliver_later
      SupportMailer.admin_new_ticket(@ticket).deliver_later
      redirect_to support_ticket_path(@ticket),
                  notice: "Votre demande a été envoyée. Nous vous répondrons sous 24h."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @messages = @ticket.support_messages.order(:created_at)
    @reply    = SupportMessage.new
  end

  def reply
    @reply = @ticket.support_messages.build(
      user:          current_user,
      body:          params[:support_message][:body],
      is_admin_reply: false
    )
    if @reply.save
      SupportMailer.admin_user_replied(@ticket, @reply).deliver_later
      redirect_to support_ticket_path(@ticket), notice: "Message envoyé."
    else
      @messages = @ticket.support_messages.order(:created_at)
      render :show, status: :unprocessable_entity
    end
  end

  def close
    @ticket.update!(status: 'closed')
    redirect_to support_tickets_path, notice: "Ticket marqué comme résolu. Merci !"
  end

  private

  def set_ticket
    @ticket = current_user.support_tickets.find(params[:id])
  end

  def ticket_params
    params.require(:support_ticket).permit(:subject, :priority, :category)
  end

  def require_paid_plan!
    unless current_user.has_active_subscription?
      redirect_to pricing_select_path,
                  alert: "Le support prioritaire est disponible à partir du plan Propriétaire (39€/mois)."
    end
  end
end
