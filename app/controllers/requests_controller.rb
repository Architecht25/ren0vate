class RequestsController < ApplicationController
  def index
    @requests = current_user.requests.order(created_at: :desc)
  end

  def show
    @request = Request.find(params[:id])
  end

  def new
    @request = Request.new
    # Charger les primes pour le prime_card_controller
    @primes = Prime.all
  end

  def create
    @request = Request.new(request_params)
    @request.user = current_user  # Assigner l'utilisateur connecté

    # Pour les brouillons, assigner des valeurs par défaut si nécessaire
    if params[:commit] == "Sauvegarder en brouillon"
      @request.status = 'draft'
      @request.title = @request.title.present? ? @request.title : "Brouillon #{Time.current.strftime('%d/%m/%Y %H:%M')}"
      @request.description = @request.description.present? ? @request.description : "Brouillon en cours de rédaction"
      @request.region = @request.region.present? ? @request.region : nil
    else
      @request.status = 'draft' if @request.status.blank?  # Statut par défaut
    end

    # Debug logs
    Rails.logger.info "REQUEST DEBUG: All params = #{params.inspect}"
    Rails.logger.info "REQUEST DEBUG: commit param = '#{params[:commit]}'"
    Rails.logger.info "REQUEST DEBUG: Request params = #{request_params}"
    Rails.logger.info "REQUEST DEBUG: Request attributes = #{@request.attributes}"
    Rails.logger.info "REQUEST DEBUG: Valid? = #{@request.valid?}"
    Rails.logger.info "REQUEST DEBUG: Errors = #{@request.errors.full_messages}" unless @request.valid?

    if @request.save
      # Redirection selon le type d'action
      Rails.logger.info "REQUEST DEBUG: Checking commit param: '#{params[:commit]}' == 'Sauvegarder en brouillon' ? #{params[:commit] == 'Sauvegarder en brouillon'}"

      if params[:commit] == "Sauvegarder en brouillon"
        @request.update(status: 'draft')
        Rails.logger.info "REQUEST DEBUG: Saving as draft and redirecting to requests_path"
        redirect_to requests_path, notice: 'Brouillon sauvegardé avec succès.'
      else
        # "Créer la demande" - Marquer comme soumise et rediriger vers le site officiel
        @request.update(status: 'submitted')

        # URL selon la région
        official_url = case @request.region
                      when 'flandre'
                        'https://www.vlaanderen.be/premies-pour-renovation/mijn-verbouwpremie'
                      when 'wallonie'
                        'https://energie.wallonie.be/fr/aides-et-primes.html?IDC=10717'
                      when 'bruxelles'
                        'https://www.brussels.be/logement-et-energie/renovation-de-mon-logement/primes'
                      else
                        requests_path
                      end

        if official_url == requests_path
          redirect_to requests_path, notice: 'Demande créée avec succès.'
        else
          redirect_to official_url, notice: 'Demande créée avec succès. Vous êtes redirigé vers le site officiel pour finaliser votre dépôt.', allow_other_host: true
        end
      end
    else
      Rails.logger.error "REQUEST SAVE FAILED: #{@request.errors.full_messages}"
      flash.now[:alert] = "Erreurs: #{@request.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @request = Request.find(params[:id])
  end

  def update
    @request = Request.find(params[:id])
    if @request.update(request_params)
      redirect_to @request
    else
      render :edit
    end
  end

  def destroy
    @request = Request.find(params[:id])

    # Vérifier que la demande peut être supprimée et appartient à l'utilisateur
    unless @request.user == current_user
      redirect_to requests_path, alert: "Vous n'êtes pas autorisé à supprimer cette demande."
      return
    end

    unless @request.can_be_deleted?
      redirect_to requests_path, alert: "Cette demande ne peut pas être supprimée car elle n'est plus en brouillon."
      return
    end

    @request.destroy
    redirect_to requests_path, notice: "Demande supprimée avec succès."
  end

  private

  def request_params
    params.require(:request).permit(:title, :description, :status, :region, :property_id,
                                   # Paramètres Bruxelles
                                   :revenus_menage, :nombre_personnes, :type_travaux, :surface_travaux, :cout_estime,
                                   # Paramètres Wallonie
                                   :revenus_reference, :composition_menage, :categories_travaux, :logement_principal, :montant_travaux,
                                   # Paramètres Flandre originaux
                                   :inkomen_gezin, :gezinssamenstelling, :type_renovatie, :eigenaar_bewoner, :kostprijs_werken,
                                   # Nouveaux paramètres Flandre optimisés
                                   :domicile, :type_demandeur, :registre_national, :nom, :prenom, :telephone, :email,
                                   :ean, :parcelle, :adresse, :code_postal, :commune, :type_bien, :usage,
                                   :chauffage_post_renovation, :travaux_toiture, :travaux_murs, :travaux_sol,
                                   :travaux_vitrage, :travaux_chauffage, :travaux_complementaires, :travaux_ventilation,
                                   :travaux_solaire, :revenus_annuels, :personnes_charge, :annee_aer, :compte_bancaire,
                                   :email_contact, :telephone_contact, :confirmation_veracite, :acceptation_conditions,
                                   # Support pour les fichiers
                                   :document_devis, :document_factures, :document_aer, :document_peb,
                                   :document_attestations, :document_photos, :document_autres,
                                   document_devis: [], document_factures: [], document_attestations: [], document_photos: [], document_autres: [])
  end
end
