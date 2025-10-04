class RequestsController < ApplicationController
  def index
    # Récupérer et trier les demandes par région de la propriété (Flandre → Bruxelles → Wallonie)
    @requests = current_user.requests.includes(:property).order(created_at: :desc).sort_by do |request|
      case request.property&.region&.downcase
      when 'flandre' then 1
      when 'bruxelles' then 2
      when 'wallonie' then 3
      else 4 # Demandes sans propriété ou sans région en dernier
      end
    end
  end

  def show
    # Éviter de traiter 'new' comme un ID
    if params[:id] == 'new'
      redirect_to new_request_path and return
    end

    @request = Request.find(params[:id])
  end

  def new
    # Ne créer qu'un objet en mémoire, pas de sauvegarde automatique
    @request = current_user.requests.build(status: 'draft')

    # Si form_type et property_id sont spécifiés, préparer le formulaire directement
    if params[:form_type].present? && params[:property_id].present?
      @property = current_user.properties.find(params[:property_id])
      @request.form_type = params[:form_type]
      @request.template_version = '1.0'
      @request.region = @property.region
      @request.property = @property

      # Valeurs par défaut pour éviter les erreurs de validation
      @request.title = "Demande #{params[:form_type].humanize} - #{@property.full_address}"
      @request.description = "Demande de prime pour #{params[:form_type].humanize}"

      @form_data = build_formulaire_data(@property)

      # Charger les primes pour le prime_card_controller
      @primes = Prime.all

      # S'assurer que @request n'est PAS persisté
      Rails.logger.info "=== NEW REQUEST DEBUG ==="
      Rails.logger.info "Request persisted? #{@request.persisted?}"
      Rails.logger.info "Request ID: #{@request.id}"
      Rails.logger.info "Property: #{@property.id} - #{@property.full_address}"
      Rails.logger.info "Form type: #{@request.form_type}"
      Rails.logger.info "Region: #{@request.region}"

      return
    end

    # Sinon, afficher la sélection de biens et formulaires
    @properties = current_user.properties.includes(:projects, :requests)
    @properties_by_region = @properties.group_by(&:region)

    # Charger la configuration des formulaires pour chaque région
    @available_forms = {}
    @properties_by_region.each do |region, properties|
      @available_forms[region] = get_available_forms_for_region(region)
    end
  end

  def create
    @request = Request.new(request_params)
    @request.user = current_user

    # Debug: Vérifier que form_data est bien rempli
    Rails.logger.info "=== REQUEST CREATE DEBUG ==="
    Rails.logger.info "Form type: #{@request.form_type}"
    Rails.logger.info "Form data: #{@request.form_data}"
    Rails.logger.info "Commit param: #{params[:commit]}"
    Rails.logger.info "All request params: #{request_params.inspect}"

    # Déterminer le statut selon l'action
    case params[:commit]
    when "Sauvegarder en brouillon"
      @request.status = 'draft'
      @request.title = @request.title.present? ? @request.title : "Brouillon #{Time.current.strftime('%d/%m/%Y %H:%M')}"
      @request.description = @request.description.present? ? @request.description : "Brouillon en cours de rédaction"
    when "Créer la demande"
      @request.status = 'submitted'
      # S'assurer que title et description sont présents pour une demande soumise
      unless @request.title.present?
        @request.title = "Demande #{@request.form_type&.humanize} - #{Time.current.strftime('%d/%m/%Y')}"
      end
      unless @request.description.present?
        @request.description = "Demande de prime pour #{@request.form_type&.humanize}"
      end
    else
      # Par défaut, créer en brouillon
      @request.status = 'draft'
      @request.title = @request.title.present? ? @request.title : "Brouillon #{Time.current.strftime('%d/%m/%Y %H:%M')}"
      @request.description = @request.description.present? ? @request.description : "Brouillon en cours de rédaction"
    end

    # Sauvegarder la demande
    if @request.save
      case params[:commit]
      when "Sauvegarder en brouillon"
        respond_to do |format|
          format.html { redirect_to edit_request_path(@request), notice: 'Formulaire sauvegardé avec succès. Vous pouvez continuer à le compléter.' }
          format.json { render json: { success: true, request_id: @request.id, redirect: edit_request_url(@request) } }
        end
      when "Créer la demande"
        # Pour une demande soumise, rediriger vers la liste ou le site officiel
        if @request.valid?
          @request.submitted_at = Time.current
          @request.save!

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
        else
          # S'il y a des erreurs de validation, rester en brouillon
          @request.status = 'draft'
          @request.save(validate: false)
          flash.now[:alert] = "Votre demande a été sauvegardée en brouillon. Veuillez compléter les champs manquants : #{@request.errors.full_messages.join(', ')}"

          # Charger les données nécessaires pour la vue
          @primes = Prime.all
          if params[:property_id].present?
            @property = current_user.properties.find(params[:property_id])
            @form_data = build_formulaire_data(@property)
          else
            @form_data = build_user_data
          end

          render :new, status: :unprocessable_entity
        end
      else
        # Autres cas - rediriger vers l'édition
        redirect_to edit_request_path(@request), notice: 'Demande créée avec succès.'
      end
    else
      Rails.logger.error "REQUEST SAVE FAILED: #{@request.errors.full_messages}"

      respond_to do |format|
        format.html do
          flash.now[:alert] = "Erreurs: #{@request.errors.full_messages.join(', ')}"

          # Charger les données nécessaires pour la vue
          @primes = Prime.all
          if params[:property_id].present?
            @property = current_user.properties.find(params[:property_id])
            @form_data = build_formulaire_data(@property)
          else
            @form_data = build_user_data
          end

          render :new, status: :unprocessable_entity
        end
        format.json { render json: { success: false, errors: @request.errors.full_messages } }
      end
    end
  end

  def edit
    @request = Request.find(params[:id])

    # Charger les primes pour le prime_card_controller
    @primes = Prime.all

    # Charger la propriété associée pour les données de pré-remplissage
    @property = @request.property

    # Préparer les données de formulaire si une propriété est associée
    if @property.present?
      @form_data = build_formulaire_data(@property)
    else
      @form_data = build_user_data
    end
  end

  def update
    @request = Request.find(params[:id])

    # Gérer les brouillons pour la mise à jour aussi
    if params[:commit] == "Sauvegarder en brouillon"
      @request.status = 'draft'
      # Assigner les nouvelles valeurs
      @request.assign_attributes(request_params)
      @request.title = @request.title.present? ? @request.title : "Brouillon #{Time.current.strftime('%d/%m/%Y %H:%M')}"
      @request.description = @request.description.present? ? @request.description : "Brouillon en cours de rédaction"
    elsif params[:commit] == "Créer la demande"
      @request.assign_attributes(request_params)
      @request.status = 'submitted'
    else
      @request.assign_attributes(request_params)
    end

    if @request.save
      if params[:commit] == "Sauvegarder en brouillon"
        redirect_to requests_path, notice: 'Brouillon mis à jour avec succès.'
      elsif params[:commit] == "Créer la demande"
        # Redirection vers le site officiel
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
          redirect_to requests_path, notice: 'Demande mise à jour avec succès.'
        else
          redirect_to official_url, notice: 'Demande soumise avec succès. Vous êtes redirigé vers le site officiel pour finaliser votre dépôt.', allow_other_host: true
        end
      else
        redirect_to @request, notice: 'Demande mise à jour avec succès.'
      end
    else
      flash.now[:alert] = "Erreurs: #{@request.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
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

  # Endpoint pour l'auto-save AJAX
  def autosave
    @request = Request.find(params[:id])

    # Vérifier les permissions
    unless @request.user == current_user
      render json: { success: false, error: "Non autorisé" }, status: :forbidden
      return
    end

    # Permettre l'auto-save uniquement pour les brouillons
    unless @request.draft? || @request.can_be_edited?
      render json: { success: false, error: "Demande non modifiable" }, status: :unprocessable_entity
      return
    end

    # Filtrer les paramètres pour l'auto-save (paramètres permis mais flexibles)
    autosave_params = params.require(:request).permit!.to_h

    # Assurer que le statut reste en brouillon pour l'auto-save
    autosave_params['status'] = 'draft'

    begin
      # Mise à jour sans validation stricte pour l'auto-save
      @request.assign_attributes(autosave_params)

      # Sauvegarder sans validations pour l'auto-save
      if @request.save(validate: false)
        render json: {
          success: true,
          message: "Auto-save réussi",
          updated_at: @request.updated_at
        }
      else
        render json: {
          success: false,
          error: "Erreur lors de la sauvegarde",
          errors: @request.errors.full_messages
        }
      end
    rescue => e
      Rails.logger.error "Erreur auto-save request #{@request.id}: #{e.message}"
      render json: {
        success: false,
        error: "Erreur serveur lors de l'auto-save"
      }
    end
  end

  def get_available_forms_for_property(property)
    forms = []

    # Si property est nil, retourner tous les formulaires pour toutes les régions
    if property.nil?
      # Formulaires Bruxelles
      forms += [
        { id: :regional_bruxelles, name: 'Prime régionale habitation', region: 'bruxelles', category: 'Rénovation' },
        { id: :monuments_bruxelles, name: 'Monuments & Sites classés', region: 'bruxelles', category: 'Patrimoine' },
        { id: :patrimoine_bruxelles, name: 'Petit patrimoine populaire', region: 'bruxelles', category: 'Patrimoine' },
        { id: :communal_bruxelles, name: 'Primes communales', region: 'bruxelles', category: 'Communal' }
      ]

      # Formulaires Wallonie
      forms += [
        { id: :regional_wallonie, name: 'Prime régionale habitation', region: 'wallonie', category: 'Rénovation' },
        { id: :audit_wallonie, name: 'Audit énergétique', region: 'wallonie', category: 'Audit' },
        { id: :monuments_wallonie, name: 'Monuments & Sites classés', region: 'wallonie', category: 'Patrimoine' },
        { id: :communal_wallonie, name: 'Primes communales', region: 'wallonie', category: 'Communal' }
      ]

      # Formulaires Flandre
      forms += [
        { id: :regional_flandre, name: 'Prime régionale habitation', region: 'flandre', category: 'Rénovation' },
        { id: :monuments_flandre, name: 'Monuments & Sites', region: 'flandre', category: 'Patrimoine' },
        { id: :communal_flandre, name: 'Primes communales', region: 'flandre', category: 'Communal' }
      ]

      return forms
    end

    # Logique spécifique à la propriété (si nécessaire)
    case property.region&.downcase
    when 'bruxelles'
      forms += [
        { id: :regional_bruxelles, name: 'Prime régionale habitation', region: 'bruxelles', category: 'Rénovation', eligible: true },
        { id: :monuments_bruxelles, name: 'Monuments & Sites classés', region: 'bruxelles', category: 'Patrimoine', eligible: true },
        { id: :patrimoine_bruxelles, name: 'Petit patrimoine populaire', region: 'bruxelles', category: 'Patrimoine', eligible: true },
        { id: :communal_bruxelles, name: 'Primes communales', region: 'bruxelles', category: 'Communal', eligible: true }
      ]
    when 'wallonie'
      forms += [
        { id: :regional_wallonie, name: 'Prime régionale habitation', region: 'wallonie', category: 'Rénovation', eligible: true },
        { id: :audit_wallonie, name: 'Audit énergétique', region: 'wallonie', category: 'Audit', eligible: true },
        { id: :monuments_wallonie, name: 'Monuments & Sites classés', region: 'wallonie', category: 'Patrimoine', eligible: true },
        { id: :communal_wallonie, name: 'Primes communales', region: 'wallonie', category: 'Communal', eligible: true }
      ]
    when 'flandre'
      forms += [
        { id: :regional_flandre, name: 'Prime régionale habitation', region: 'flandre', category: 'Rénovation', eligible: true },
        { id: :monuments_flandre, name: 'Monuments & Sites', region: 'flandre', category: 'Patrimoine', eligible: true },
        { id: :communal_flandre, name: 'Primes communales', region: 'flandre', category: 'Communal', eligible: true }
      ]
    end

    forms
  end

  def get_available_forms_for_region(region)
    forms = get_available_forms_for_property(nil) # Récupérer tous les formulaires
    # Normaliser la région en minuscules pour la comparaison
    normalized_region = region&.downcase
    forms.select { |form| form[:region] == normalized_region }
  end

  private

  def request_params
    permitted_params = params.require(:request).permit(:title, :description, :status, :region, :property_id, :form_type, :template_version,
                                   # Paramètres Bruxelles
                                   :revenus_menage, :nombre_personnes, :type_travaux, :surface_travaux, :cout_estime,
                                   # Paramètres Wallonie
                                   :revenus_reference, :composition_menage, :categories_travaux, :logement_principal, :montant_travaux,
                                   :numero_audit, :date_audit, :numero_agrement_auditeur, :nom_auditeur, :adresse_auditeur,
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

    Rails.logger.info "=== REQUEST_PARAMS DEBUG ==="
    Rails.logger.info "Permitted params keys: #{permitted_params.keys}"
    Rails.logger.info "Title: #{permitted_params[:title]}"
    Rails.logger.info "Form type: #{permitted_params[:form_type]}"
    Rails.logger.info "Region: #{permitted_params[:region]}"
    Rails.logger.info "Property ID: #{permitted_params[:property_id]}"

    # Extraire les données de formulaire et les stocker dans form_data
    extract_form_data_from_params(permitted_params)
  end

  def extract_form_data_from_params(permitted_params)
    # Champs de base du modèle Request (ne vont pas dans form_data)
    base_fields = [:title, :description, :status, :region, :property_id, :form_type, :template_version]

    # Champs de fichiers (ne vont pas dans form_data)
    file_fields = [:document_devis, :document_factures, :document_aer, :document_peb,
                   :document_attestations, :document_photos, :document_autres]

    # Extraire les données de formulaire (tous les autres champs)
    form_data_fields = permitted_params.except(*base_fields, *file_fields).reject { |k, v| v.blank? }

    # Ajouter form_data aux paramètres si il y a des données
    if form_data_fields.present?
      permitted_params[:form_data] = form_data_fields
    end

    # Retourner seulement les champs de base + form_data + fichiers
    permitted_params.slice(*base_fields, *file_fields, :form_data)
  end

  # Méthodes de pré-remplissage
  def build_formulaire_data(property)
    # Données de base de pré-remplissage
    base_data = {
      # Données du demandeur
      nom: current_user.last_name,
      prenom: current_user.first_name,
      email: current_user.email,
      telephone: current_user.phone,
      registre_national: current_user.national_number,
      profil_demandeur: property.profil_demandeur,

      # Variations pour formulaires officiels
      applicant_firstname: current_user.first_name,
      applicant_lastname: current_user.last_name,
      applicant_email: current_user.email,
      applicant_phone: current_user.phone,
      applicant_national_number: current_user.national_number,
      applicant_address: current_user.street,
      applicant_number: current_user.number,
      applicant_postal_code: current_user.postal_code,
      applicant_city: current_user.city,

      # Données du bien
      ean: property.ean_flandre || property.numero_ean,
      adresse: "#{property.numero} #{property.rue}",
      code_postal: property.code_postal,
      commune: property.commune,
      heritage_address: property.rue,
      heritage_number: property.numero,
      heritage_postal_code: property.code_postal,
      heritage_city: property.commune,

      # Type et usage selon la région
      type_bien: map_property_type(property),
      usage: map_property_usage(property),
      parcelle: property.parcelle_flandre || property.numero_cadastre,
      chauffage_post_renovation: property.chauffage_post_renovation_flandre,

      # Données travaux (par défaut non cochées pour permettre l'affichage)
      travaux_toiture: false,
      travaux_murs: false,
      travaux_sol: false,
      travaux_fenetres: false,
      travaux_chauffage: false,
      travaux_ventilation: false,
      travaux_photovoltaique: false,
      travaux_chauffe_eau: false
    }

    # Fusionner avec les données existantes du form_data si présentes
    if @request.present? && @request.form_data.present?
      base_data.merge(@request.form_data.deep_symbolize_keys)
    else
      base_data
    end
  end

  def build_user_data
    # Données de base de l'utilisateur
    base_data = {
      nom: current_user.last_name,
      prenom: current_user.first_name,
      email: current_user.email,
      telephone: current_user.phone,
      registre_national: current_user.national_number,

      # Variations pour formulaires officiels
      applicant_firstname: current_user.first_name,
      applicant_lastname: current_user.last_name,
      applicant_email: current_user.email,
      applicant_phone: current_user.phone,
      applicant_national_number: current_user.national_number,
      applicant_address: current_user.street,
      applicant_number: current_user.number,
      applicant_postal_code: current_user.postal_code,
      applicant_city: current_user.city
    }

    # Fusionner avec les données existantes du form_data si présentes
    if @request.present? && @request.form_data.present?
      base_data.merge(@request.form_data.deep_symbolize_keys)
    else
      base_data
    end
  end

  def map_property_type(property)
    case property.region&.downcase
    when 'flandre'
      property.type_bien_flandre
    when 'wallonie'
      property.type_propriete_wallonie
    when 'bruxelles'
      property.type_bien_bruxelles
    else
      property.type
    end
  end

  def map_property_usage(property)
    case property.region&.downcase
    when 'flandre'
      property.usage_flandre
    else
      property.usage || property.occupation
    end
  end
end
