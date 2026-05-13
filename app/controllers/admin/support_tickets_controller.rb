class Admin::SupportTicketsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_ticket, only: [:show, :reply, :resolve, :close]

  def index
    scope = SupportTicket.includes(:user, :support_messages).recent
    scope = scope.where(status: params[:status])   if params[:status].present?
    scope = scope.where(priority: params[:priority]) if params[:priority].present?

    @tickets       = scope
    @total_count   = SupportTicket.count
    @by_status     = SupportTicket.group(:status).count
    @open_count    = @by_status.slice('open', 'in_progress').values.sum
    @overdue_count = SupportTicket.overdue.count
  end

  def show
    @messages = @ticket.support_messages.order(:created_at)
    @reply    = SupportMessage.new
  end

  def reply
    @reply = @ticket.support_messages.build(
      user:           current_user,
      body:           params[:support_message][:body],
      is_admin_reply: true
    )
    if @reply.save
      SupportMailer.user_admin_replied(@ticket, @reply).deliver_later
      redirect_to admin_support_ticket_path(@ticket), notice: "Réponse envoyée à #{@ticket.user.email}."
    else
      @messages = @ticket.support_messages.order(:created_at)
      render :show, status: :unprocessable_entity
    end
  end

  def resolve
    @ticket.update!(status: 'resolved')
    SupportMailer.ticket_resolved(@ticket).deliver_later
    redirect_to admin_support_tickets_path, notice: "Ticket marqué comme résolu."
  end

  def close
    @ticket.update!(status: 'closed')
    redirect_to admin_support_tickets_path, notice: "Ticket fermé."
  end

  private

  def set_ticket
    @ticket = SupportTicket.find(params[:id])
  end

  def ensure_admin
    redirect_to root_path, alert: "Accès refusé." unless current_user.admin?
  end
end
