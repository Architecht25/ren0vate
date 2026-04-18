class FacturesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:index, :dashboard, :upload_facture, :validate_facture]
  before_action :set_facture, only: [:show, :edit, :update, :destroy, :validate_by_client]

  # GET /projects/:project_id/factures
  def index
    @factures = @project.factures.includes(:document).order(:date_facture)
    @validation_service = FactureValidationService.new(@project)
    @analyse = @validation_service.analyser_factures
  end

  # GET /projects/:project_id/factures/dashboard
  def dashboard
    @validation_service = FactureValidationService.new(@project)
    @analyse = @validation_service.analyser_factures

    @factures_devis = @project.factures_devis.includes(:document)
    @factures_travaux = @project.factures_travaux.includes(:document).order(:date_facture)

    # Statistiques pour le dashboard
    @stats = calcul_statistiques
  end

  # POST /projects/:project_id/factures/upload_facture
  def upload_facture
    return render json: { error: 'Aucun fichier fourni' }, status: :bad_request unless params[:file]

    begin
      # Créer d'abord le document
      document_params = {
        user: current_user,
        project: @project,
        property: @project.property,
        type_document: 'facture',
        status: 'pending'
      }

      @document = Document.new(document_params)
      @document.file.attach(params[:file])

      if @document.save
        # Effectuer l'extraction OCR spécialisée pour factures
        facture_ocr_service = FactureOcrService.new(params[:file])
        ocr_result = facture_ocr_service.extraire_donnees_facture

        if ocr_result[:success] && ocr_result[:donnees_facture]
          # Créer l'enregistrement Facture avec les données extraites (même partielles)
          @facture = creer_facture_depuis_ocr(@document, ocr_result)
          extraction_partielle = @facture.montant.to_f == 0 || !@facture.extraction_complete

          render json: {
            success: true,
            document: document_json(@document),
            facture: facture_json(@facture),
            ocr_result: ocr_result,
            message: extraction_partielle ? 'Facture enregistrée — extraction partielle, veuillez compléter les données manuellement' : 'Facture uploadée et analysée avec succès'
          }
        else
          render json: {
            error: 'Erreur lors de l\'extraction des données de facture',
            details: ocr_result[:error]
          }, status: :unprocessable_entity
        end
      else
        render json: {
          error: 'Erreur lors de la création du document',
          details: @document.errors.full_messages
        }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Erreur upload facture: #{e.message}"
      render json: {
        error: 'Erreur lors du traitement de la facture',
        details: Rails.env.development? ? e.message : nil
      }, status: :internal_server_error
    end
  end

  # PATCH /factures/:id/validate
  def validate_facture
    @facture = Facture.find(params[:id])
    unless @facture.project_id == @project.id
      render json: { error: "Accès non autorisé" }, status: :forbidden and return
    end

    if @facture.update(facture_params.merge(valide_manuellement: true))
      # Recalculer les analyses après validation
      @validation_service = FactureValidationService.new(@project)
      @analyse = @validation_service.analyser_factures

      render json: {
        success: true,
        facture: facture_json(@facture),
        analyse: @analyse,
        message: 'Facture validée avec succès'
      }
    else
      render json: {
        error: 'Erreur lors de la validation',
        details: @facture.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /factures/:id/validate_by_client
  # Le propriétaire du projet valide le devis/facture uploadé par l'entrepreneur
  def validate_by_client
    # Seul le propriétaire du projet peut valider
    unless @facture.project.user_id == current_user.id
      redirect_back fallback_location: root_path, alert: "Vous n'êtes pas autorisé à valider ce document." and return
    end

    if @facture.validated_by_client_at.present?
      redirect_back fallback_location: root_path, notice: "Ce document est déjà validé." and return
    end

    if @facture.update(validated_by_client_at: Time.current, validated_by_client_id: current_user.id)
      redirect_back fallback_location: pro_view_project_path(@facture.project),
                    notice: "Devis validé ✓ — #{@facture.nom_entreprise.presence || 'Entrepreneur'} a été notifié."
    else
      redirect_back fallback_location: root_path, alert: "Erreur lors de la validation."
    end
  end

  # GET /factures/:id
  def show
    @document = @facture.document
    @project = @facture.project
  end

  # GET /factures/:id/edit
  def edit
    @document = @facture.document
    @project = @facture.project
  end

  # PATCH /factures/:id
  def update
    if @facture.update(facture_params)
      redirect_to @facture, notice: 'Facture mise à jour avec succès.'
    else
      render :edit
    end
  end

  # DELETE /factures/:id
  def destroy
    project = @facture.project
    @facture.destroy
    redirect_to project_factures_path(project), notice: 'Facture supprimée.'
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_facture
    @facture = current_user.projects.joins(:factures).find_by(factures: { id: params[:id] })&.factures&.find(params[:id])
    redirect_to root_path, alert: 'Facture non trouvée' unless @facture
  end

  def facture_params
    params.require(:facture).permit(
      :montant, :numero_facture, :date_facture, :date_echeance,
      :type_facture, :statut_paiement, :nom_entreprise,
      :numero_tva_entreprise, :numero_bce_entreprise,
      :montant_ht, :montant_tva, :taux_tva, :facture_solde,
      :type_intervenant, :adresse_entreprise, :telephone_entreprise, :email_entreprise
    )
  end

  def creer_facture_depuis_ocr(document, ocr_result)
    donnees = ocr_result[:donnees_facture]

    facture_attrs = {
      document: document,
      project: @project,
      property: @project.property,
      montant: donnees[:montant] || 0,
      numero_facture: donnees[:numero_facture],
      date_facture: donnees[:date_facture],
      type_facture: donnees[:type_facture] || 'facture',
      nom_entreprise: donnees[:nom_entreprise],
      numero_bce_entreprise: donnees[:numero_bce],
      adresse_entreprise: donnees[:adresse_entreprise],
      telephone_entreprise: donnees[:telephone_entreprise],
      email_entreprise: donnees[:email_entreprise],
      montant_ht: donnees[:montant_ht],
      montant_tva: donnees[:montant_tva],
      taux_tva: donnees[:taux_tva],
      confiance_ocr: ocr_result[:confiance_extraction],
      extraction_complete: ocr_result[:extraction_complete],
      texte_ocr_brut: ocr_result[:texte_brut],
      donnees_extraites: donnees,
      type_intervenant: detecter_type_intervenant(donnees[:nom_entreprise]),
      valide_manuellement: false
    }

    Facture.create!(facture_attrs)
  end

  # Détecte si la facture provient de l'architecte ou d'un entrepreneur
  # en comparant le nom d'entreprise avec les données du projet
  def detecter_type_intervenant(nom_entreprise)
    return 'entrepreneur' if nom_entreprise.blank?

    nom = nom_entreprise.downcase.strip
    arch = @project.architecte_entreprise&.downcase&.strip

    return 'architecte' if arch.present? && nom.include?(arch.split.first || '')

    'entrepreneur'
  end

  def calcul_statistiques
    {
      total_devis: @project.factures_devis.sum(:montant),
      total_factures: @project.factures_travaux.sum(:montant),
      nombre_factures: @project.factures_travaux.count,
      factures_validees: @project.factures.where(valide_manuellement: true).count,
      extraction_moyenne: @project.factures.average(:confiance_ocr)&.round(1) || 0
    }
  end

  def document_json(document)
    {
      id: document.id,
      type_document: document.type_document,
      file_url: document.file.attached? ? url_for(document.file) : document.file_url,
      status: document.status,
      created_at: document.created_at
    }
  end

  def facture_json(facture)
    {
      id: facture.id,
      montant: facture.montant,
      montant_formate: facture.montant_formate,
      numero_facture: facture.numero_facture,
      date_facture: facture.date_facture,
      date_facture_display: facture.date_facture_display,
      type_facture: facture.type_facture,
      nom_entreprise: facture.nom_entreprise,
      confiance_ocr: facture.confiance_ocr,
      confiance_display: facture.confiance_display,
      extraction_complete: facture.extraction_complete,
      valide_manuellement: facture.valide_manuellement,
      facture_solde: facture.facture_solde,
      message_alerte_delai: facture.message_alerte_delai,
      couleur_alerte_delai: facture.couleur_alerte_delai
    }
  end
end
