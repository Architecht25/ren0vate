class ProjectDocumentCommentsController < ApplicationController
  before_action :set_project_document

  def create
    authorize @project_document, :comment?
    comment = @project_document.comments.build(comment_params)
    comment.author = current_user

    if comment.save
      AuditEvent.record!(action: "project_document.commented", auditable: @project_document, actor: current_user, ip_address: request.remote_ip)
      redirect_to project_document_path(@project_document), notice: "Commentaire ajouté."
    else
      redirect_to project_document_path(@project_document), alert: comment.errors.full_messages.to_sentence
    end
  end

  private

  def set_project_document
    @project_document = ProjectDocument.find(params[:project_document_id])
  end

  def comment_params
    params.require(:project_document_comment).permit(:body, :project_document_version_id)
  end
end
