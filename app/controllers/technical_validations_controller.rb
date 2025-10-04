class TechnicalValidationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_or_moderator, only: [:index]
  before_action :set_project, only: [:show, :validate, :report]

  def index
    @validations = Project.joins(:user, :property)
                         .includes(:user, :property, :documents)
                         .where.not(validation_status: [nil, ''])

    # Filtres
    if params[:status].present?
      @validations = @validations.where(validation_status: params[:status])
    end

    if params[:region].present?
      @validations = @validations.joins(:property).where(properties: { region: params[:region] })
    end

    if params[:priority].present? && respond_to?(:priority)
      @validations = @validations.where(priority: params[:priority])
    end

    # Tri par défaut : les validations en attente en premier
    @validations = @validations.order(
      Arel.sql("CASE
        WHEN validation_status = 'pending' THEN 1
        WHEN validation_status = 'under_review' THEN 2
        WHEN validation_status = 'validated' THEN 3
        ELSE 4
      END"),
      created_at: :desc
    )

    # Pagination si gem Kaminari disponible
    @validations = @validations.limit(50) # Limite pour performance
  end

  def show
    @validation_service = TechnicalValidationService.new(@project)
    @validation_result = @validation_service.validate!

    @audit_document = @project.documents.where(type_document: 'rapport_audit_energetique').first
    @devis_documents = @project.documents.where(type_document: 'devis')
    @photo_documents = @project.documents.where(type_document: 'photo')
    @facture_documents = @project.documents.where(type_document: 'facture')
  end

  def validate
    @validation_service = TechnicalValidationService.new(@project)
    @validation_result = @validation_service.validate!

    if @validation_result[:valid]
      @project.update!(validation_status: 'validated', validation_score: @validation_result[:validation_score])

      render json: {
        success: true,
        message: 'Validation technique réussie',
        score: @validation_result[:validation_score],
        warnings: @validation_result[:warnings]
      }
    else
      render json: {
        success: false,
        message: 'Erreurs de validation détectées',
        errors: @validation_result[:errors],
        warnings: @validation_result[:warnings],
        score: @validation_result[:validation_score]
      }
    end
  end

  def report
    @validation_service = TechnicalValidationService.new(@project)
    @validation_result = @validation_service.validate!

    respond_to do |format|
      format.html { render :report }
      format.pdf do
        pdf = generate_validation_pdf
        send_data pdf, filename: "validation_#{@project.id}_#{Date.current.strftime('%Y%m%d')}.pdf", type: 'application/pdf'
      end
    end
  end

  def bulk_validate
    # Validation en lot pour les admins
    if current_user.can_access_admin?
      project_ids = params[:project_ids] || []
      results = []

      project_ids.each do |project_id|
        project = Project.find(project_id)
        validation_service = TechnicalValidationService.new(project)
        result = validation_service.validate!

        project.update!(
          validation_status: result[:valid] ? 'validated' : 'failed',
          validation_score: result[:validation_score],
          last_validation_at: Time.current
        )

        results << {
          project_id: project.id,
          project_name: project.nom,
          valid: result[:valid],
          score: result[:validation_score],
          errors_count: result[:errors].count,
          warnings_count: result[:warnings].count
        }
      end

      render json: {
        success: true,
        message: "#{results.count} projets validés",
        results: results
      }
    else
      render json: { success: false, message: 'Accès non autorisé' }
    end
  end

  def analytics
    # Analytics de validation pour les admins
    if current_user.can_access_admin?
      @analytics = {
        total_projects: Project.count,
        validated_projects: Project.where(validation_status: 'validated').count,
        failed_projects: Project.where(validation_status: 'failed').count,
        pending_projects: Project.where(validation_status: [nil, 'pending']).count,
        average_score: Project.where.not(validation_score: nil).average(:validation_score)&.round(1),
        by_region: validation_stats_by_region,
        recent_validations: recent_validation_activity
      }
      render :analytics
    else
      redirect_to root_path, alert: 'Accès non autorisé.'
    end
  end

  def revalidate
    # Re-validation après corrections
    @validation_service = TechnicalValidationService.new(@project)
    @validation_result = @validation_service.validate!

    @project.update!(
      validation_status: @validation_result[:valid] ? 'validated' : 'failed',
      validation_score: @validation_result[:validation_score],
      last_validation_at: Time.current
    )

    if @validation_result[:valid]
      redirect_to technical_validation_path(@project),
                  notice: 'Re-validation réussie ! Votre projet respecte maintenant toutes les exigences techniques.'
    else
      redirect_to technical_validation_path(@project),
                  alert: 'Des problèmes techniques persistent. Veuillez corriger les erreurs signalées.'
    end
  end

  def export_issues
    # Export des problèmes de validation pour traitement
    if current_user.can_access_admin?
      @projects_with_issues = Project.joins(:property)
                                    .where(validation_status: 'failed')
                                    .includes(:property, :documents, :user)

      respond_to do |format|
        format.csv do
          csv_data = generate_issues_csv
          send_data csv_data, filename: "validation_issues_#{Date.current.strftime('%Y%m%d')}.csv", type: 'text/csv'
        end
        format.json do
          render json: {
            projects: @projects_with_issues.map { |project| format_project_issues(project) }
          }
        end
      end
    else
      redirect_to root_path, alert: 'Accès non autorisé.'
    end
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: 'Projet non trouvé.'
  end

  def validation_stats_by_region
    Project.joins(:property)
           .group('properties.region')
           .group(:validation_status)
           .count
  end

  def recent_validation_activity
    Project.where.not(last_validation_at: nil)
           .order(last_validation_at: :desc)
           .limit(10)
           .includes(:property, :user)
           .map do |project|
      {
        project_id: project.id,
        project_name: project.nom,
        user_name: project.user.full_name,
        region: project.property.region,
        validation_status: project.validation_status,
        validation_score: project.validation_score,
        validated_at: project.last_validation_at
      }
    end
  end

  def generate_validation_pdf
    # Génération du PDF de rapport de validation
    # Cette méthode nécessiterait une gem comme Prawn ou WickedPDF

    html_content = render_to_string(
      template: 'technical_validations/report',
      layout: 'pdf',
      locals: {
        project: @project,
        validation_result: @validation_result,
        validation_service: @validation_service
      }
    )

    # Conversion HTML vers PDF (nécessite wkhtmltopdf ou équivalent)
    # WickedPdf.new.pdf_from_string(html_content)

    # Pour l'instant, retourner un placeholder
    "PDF de validation pour le projet #{@project.nom}"
  end

  def generate_issues_csv
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << ['Projet ID', 'Nom Projet', 'Utilisateur', 'Région', 'Score Validation', 'Dernière Validation', 'Nombre Erreurs']

      @projects_with_issues.each do |project|
        validation_service = TechnicalValidationService.new(project)
        result = validation_service.validate!

        csv << [
          project.id,
          project.nom,
          project.user.full_name,
          project.property.region,
          project.validation_score,
          project.last_validation_at&.strftime('%d/%m/%Y'),
          result[:errors].count
        ]
      end
    end
  end

  def format_project_issues(project)
    validation_service = TechnicalValidationService.new(project)
    result = validation_service.validate!

    {
      id: project.id,
      name: project.nom,
      user: project.user.full_name,
      region: project.property.region,
      validation_score: project.validation_score,
      last_validation: project.last_validation_at,
      errors: result[:errors],
      warnings: result[:warnings]
    }
  end
end
