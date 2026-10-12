# V2 — Lot 4 : messagerie par lot (cahier des charges §5.D).
class MessageThreadsController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_thread, only: %i[show]

  def index
    authorize @project, :show?
    @message_threads = policy_scope(MessageThread).where(project: @project).includes(:lot)
  end

  def new
    @message_thread = @project.message_threads.build
    authorize @message_thread, :create?
  end

  def create
    @message_thread = @project.message_threads.build(thread_params)
    authorize @message_thread, :create?

    if @message_thread.save
      redirect_to message_thread_path(@message_thread), notice: "Fil de discussion créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @message_thread, :show?
    @messages = @message_thread.messages.includes(:author).order(:created_at)
    @message = @message_thread.messages.build
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_thread
    @message_thread = MessageThread.find(params[:id])
  end

  def thread_params
    params.require(:message_thread).permit(:title, :lot_id)
  end
end
