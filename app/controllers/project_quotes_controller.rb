# V2 — Lot 2 : devis structuré (saisi manuellement poste par poste, workflow
# d'acceptation tracé), comparateur par lot. Distinct de QuotesController
# (classe `Quote`, app/models/devis/quote.rb — PAS "quasi mort" malgré ce
# qu'indiquait ce commentaire avant le 12/10/2026 : c'est une auto-estimation
# budgétaire que le particulier produit lui-même via un catalogue de prix
# régionaux, avant tout contact avec un entrepreneur — point d'entrée sidebar
# de premier niveau, avec de vraies données en production. Les deux couvrent
# des besoins différents, voir mémoire "project_v2_trois_systemes_devis_audit"
# pour le détail. Décision ouverte #6 de docs/PLAN_V2.md toujours non close.
class ProjectQuotesController < ApplicationController
  before_action :check_dossier_documentaire_access!
  before_action :set_project, only: %i[index new create]
  before_action :set_project_quote, only: %i[show decide]

  def index
    authorize_project_scope!
    @project_quotes = policy_scope(ProjectQuote).where(project: @project).includes(:lot, :lines)
  end

  def show
    authorize @project_quote
  end

  def new
    authorize_project_scope!
    @project_quote = @project.project_quotes.build
    @project_quote.lines.build
  end

  def create
    authorize_project_scope!
    @project_quote = @project.project_quotes.build(project_quote_params)
    @project_quote.submitted_by = current_user

    if @project_quote.save
      AuditEvent.record!(action: "project_quote.created", auditable: @project_quote, actor: current_user, ip_address: request.remote_ip)
      redirect_to project_quote_path(@project_quote), notice: "Devis ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def decide
    authorize @project_quote, :decide?
    status = params[:status]

    if ProjectQuote.statuses.key?(status) && @project_quote.update(status: status)
      AuditEvent.record!(action: "project_quote.decided", auditable: @project_quote, actor: current_user, ip_address: request.remote_ip, event_data: { status: status })
      redirect_to project_quote_path(@project_quote), notice: "Devis #{status}."
    else
      redirect_to project_quote_path(@project_quote), alert: "Statut invalide."
    end
  end

  def comparison
    @project = Project.find(params[:project_id])
    authorize @project, :show?
    @lot = @project.lots.find(params[:lot_id])
    @comparison = ProjectQuotes::ComparatorService.new(@lot).call
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
    authorize @project, :show?
  end

  def set_project_quote
    @project_quote = ProjectQuote.find(params[:id])
    @project = @project_quote.project
  end

  def authorize_project_scope!
    authorize @project, :show?
    raise Pundit::NotAuthorizedError unless ProjectQuotePolicy.new(current_user, @project.project_quotes.build).create?
  end

  def project_quote_params
    params.require(:project_quote).permit(:lot_id, :entreprise_nom, lines_attributes: [:description, :quantite, :unite, :prix_unitaire_ht])
  end
end
