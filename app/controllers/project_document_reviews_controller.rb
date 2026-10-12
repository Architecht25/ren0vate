class ProjectDocumentReviewsController < ApplicationController
  before_action :set_project_document

  def create
    authorize @project_document, :review?
    review = @project_document.reviews.build(review_params)
    review.reviewer = current_user
    review.project_document_version ||= @project_document.current_version

    if review.save
      AuditEvent.record!(action: "project_document.reviewed", auditable: @project_document, actor: current_user, ip_address: request.remote_ip, event_data: { status: review.status })
      redirect_to project_document_path(@project_document), notice: "Avis enregistré."
    else
      redirect_to project_document_path(@project_document), alert: review.errors.full_messages.to_sentence
    end
  end

  private

  def set_project_document
    @project_document = ProjectDocument.find(params[:project_document_id])
  end

  def review_params
    params.require(:project_document_review).permit(:status, :comment)
  end
end
