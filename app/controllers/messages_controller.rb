class MessagesController < ApplicationController
  before_action :set_thread

  def create
    @message = @message_thread.messages.build(message_params)
    authorize @message
    @message.author = current_user

    if @message.save
      redirect_to message_thread_path(@message_thread), notice: "Message envoyé."
    else
      redirect_to message_thread_path(@message_thread), alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def set_thread
    @message_thread = MessageThread.find(params[:message_thread_id])
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
