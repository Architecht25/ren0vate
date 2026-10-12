# V2 — Lot 5 : assistant conversationnel sur dossier (cahier des charges
# §4, §8.7). Pas de policy dédiée — accessible à quiconque peut voir le
# projet (ProjectPolicy#show?), la sécurité réelle est dans
# ProjectDocuments::RagAssistantService (droits appliqués avant la
# recherche vectorielle, jamais après).
class AssistantController < ApplicationController
  before_action :set_project

  def show
  end

  def ask
    result = ProjectDocuments::RagAssistantService.new(user: current_user, project: @project).ask(params[:question])
    @question = params[:question]
    @answer = result[:answer]
    @sources = result[:sources]

    AuditEvent.record!(action: "assistant.asked", auditable: @project, actor: current_user, ip_address: request.remote_ip, event_data: { question: params[:question] })

    render :show
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
    authorize @project, :show?
  end
end
