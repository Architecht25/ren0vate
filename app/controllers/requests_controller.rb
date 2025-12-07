class RequestsController < ApplicationController
  def index
    # Récupérer les demandes, filtrer par property_id si fourni
    base_requests = current_user.requests.includes(:property)

    if params[:property_id].present?
      @property = current_user.properties.find(params[:property_id])
      @requests = base_requests.where(property: @property).order(created_at: :desc)
    else
      # Récupérer et trier les demandes par région de la propriété (Flandre → Bruxelles → Wallonie)
      @requests = base_requests.order(created_at: :desc).sort_by do |request|
        case request.property&.region&.downcase
        when 'flandre' then 1
        when 'bruxelles' then 2
        when 'wallonie' then 3
        else 4 # Demandes sans propriété ou sans région en dernier
        end
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

    # Charger la configuration des formulaires pour chaque propriété
    @available_forms = {}
    @properties_by_region.each do |region, properties|
      # Créer un hash pour stocker les formulaires par propriété
      @available_forms[region] = {}
      properties.each do |property|
        @available_forms[region][property.id] = get_available_forms_for_property(property)
      end
    end
  end

  def create
    @request = Request.new(request_params)
    @request.user = current_user

    # Debug: Vérifier que form_data est bien rempli
    Rails.logger.info "=== REQUEST CREATE DEBUG ==="
    Rails.logger.info "Form type: #{@request.form_type}"
    Rails.logger.info "Form data present: #{@request.form_data.present?}"
    Rails.logger.info "Form data keys: #{@request.form_data&.keys || 'NIL'}"
    Rails.logger.info "Form data size: #{@request.form_data&.size || 0} champs"
    Rails.logger.info "Commit param: #{params[:commit]}"
    Rails.logger.info "All request params: #{request_params.inspect}"

    # Debug spécifique pour quelques champs Wallonie
    if @request.form_data.present?
      Rails.logger.info "=== FORM_DATA WALLONIE DETAILS ==="
      Rails.logger.info "  numero_audit: #{@request.form_data['numero_audit']}"
      Rails.logger.info "  date_audit: #{@request.form_data['date_audit']}"
      Rails.logger.info "  type_demandeur: #{@request.form_data['type_demandeur']}"
      Rails.logger.info "  qualite_demandeur: #{@request.form_data['qualite_demandeur']}"
      Rails.logger.info "  nom: #{@request.form_data['nom']}"
      Rails.logger.info "  prenom: #{@request.form_data['prenom']}"
    end

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

          respond_to do |format|
            format.html do
              if official_url == requests_path
                redirect_to requests_path, notice: 'Demande créée avec succès.'
              else
                redirect_to official_url, notice: 'Demande créée avec succès. Vous êtes redirigé vers le site officiel pour finaliser votre dépôt.', allow_other_host: true
              end
            end
            format.json { render json: { success: true, request_id: @request.id, redirect: official_url } }
          end
        else
          # S'il y a des erreurs de validation, rester en brouillon
          @request.status = 'draft'
          @request.save(validate: false)

          respond_to do |format|
            format.html do
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
            format.json { render json: { success: false, errors: @request.errors.full_messages, saved_as_draft: true, request_id: @request.id } }
          end
        end
      else
        # Autres cas - rediriger vers l'édition
        respond_to do |format|
          format.html { redirect_to edit_request_path(@request), notice: 'Demande créée avec succès.' }
          format.json { render json: { success: true, request_id: @request.id, redirect: edit_request_url(@request) } }
        end
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
      base_form_data = build_formulaire_data(@property)
    else
      base_form_data = build_user_data
    end

    # IMPORTANT: Fusionner avec les données existantes dans form_data
    # Les données des travaux doivent être préservées
    if @request.form_data.present?
      @form_data = base_form_data.merge(@request.form_data)
      Rails.logger.info "=== EDIT - FUSION FORM_DATA ==="
      Rails.logger.info "Base form_data keys: #{base_form_data.keys.size}"
      Rails.logger.info "Request form_data keys: #{@request.form_data.keys.size}"
      Rails.logger.info "Merged form_data keys: #{@form_data.keys.size}"
      Rails.logger.info "Surface toiture in @form_data: #{@form_data['surface_toiture'] || '[nil]'}"
      Rails.logger.info "Marque toiture in @form_data: #{@form_data['marque_toiture'] || '[nil]'}"
      Rails.logger.info "Travaux toiture in @form_data: #{@form_data['travaux_toiture'] || '[nil]'}"
    else
      @form_data = base_form_data
      Rails.logger.info "=== EDIT - PAS DE FORM_DATA EXISTANTE ==="
    end

    # CRUCIAL: Créer un objet virtuel qui combine @request avec les données de form_data
    # pour que Rails puisse pré-remplir les champs du formulaire
    form_data_safe = @form_data || {}

    @request.define_singleton_method(:surface_toiture) { form_data_safe['surface_toiture'] }
    @request.define_singleton_method(:marque_toiture) { form_data_safe['marque_toiture'] }
    @request.define_singleton_method(:methode_toiture) { form_data_safe['methode_toiture'] }
    @request.define_singleton_method(:date_placement_toiture) { form_data_safe['date_placement_toiture'] }
    @request.define_singleton_method(:materiau_toiture) { form_data_safe['materiau_toiture'] }
    @request.define_singleton_method(:type_isolation_toiture) { form_data_safe['type_isolation_toiture'] }

    # Ajouter les méthodes pour les murs
    @request.define_singleton_method(:surface_murs) { form_data_safe['surface_murs'] }
    @request.define_singleton_method(:marque_murs) { form_data_safe['marque_murs'] }
    @request.define_singleton_method(:methode_murs) { form_data_safe['methode_murs'] }
    @request.define_singleton_method(:date_placement_murs) { form_data_safe['date_placement_murs'] }
    @request.define_singleton_method(:materiau_murs) { form_data_safe['materiau_murs'] }
    @request.define_singleton_method(:type_isolation_murs) { form_data_safe['type_isolation_murs'] }

    # Ajouter les méthodes pour le sol
    @request.define_singleton_method(:surface_sol) { form_data_safe['surface_sol'] }
    @request.define_singleton_method(:marque_sol) { form_data_safe['marque_sol'] }
    @request.define_singleton_method(:methode_sol) { form_data_safe['methode_sol'] }
    @request.define_singleton_method(:date_placement_sol) { form_data_safe['date_placement_sol'] }
    @request.define_singleton_method(:materiau_sol) { form_data_safe['materiau_sol'] }
    @request.define_singleton_method(:type_isolation_sol) { form_data_safe['type_isolation_sol'] }

    # Ajouter les méthodes pour vitrage, chauffage, ventilation
    @request.define_singleton_method(:surface_vitrage) { form_data_safe['surface_vitrage'] }
    @request.define_singleton_method(:type_vitrage) { form_data_safe['type_vitrage'] }
    @request.define_singleton_method(:date_placement_vitrage) { form_data_safe['date_placement_vitrage'] }
    @request.define_singleton_method(:marque_vitrage) { form_data_safe['marque_vitrage'] }

    @request.define_singleton_method(:type_systeme_chauffage) { form_data_safe['type_systeme_chauffage'] }
    @request.define_singleton_method(:date_placement_chauffage) { form_data_safe['date_placement_chauffage'] }
    @request.define_singleton_method(:marque_chauffage) { form_data_safe['marque_chauffage'] }

    @request.define_singleton_method(:type_systeme_ventilation) { form_data_safe['type_systeme_ventilation'] }
    @request.define_singleton_method(:date_placement_ventilation) { form_data_safe['date_placement_ventilation'] }
    @request.define_singleton_method(:marque_ventilation) { form_data_safe['marque_ventilation'] }

    @request.define_singleton_method(:description_complementaires) { form_data_safe['description_complementaires'] }

    Rails.logger.info "=== OBJET VIRTUEL CRÉÉ ==="
    Rails.logger.info "Surface toiture method: #{@request.surface_toiture || '[nil]'}"
    Rails.logger.info "Marque toiture method: #{@request.marque_toiture || '[nil]'}"
    Rails.logger.info "Méthode toiture method: #{@request.methode_toiture || '[nil]'}"
    Rails.logger.info ""
    Rails.logger.info "=== VÉRIFICATION @form_data POUR SELECT ==="
    Rails.logger.info "methode_toiture dans @form_data: #{@form_data['methode_toiture'].inspect}"
  end

  def update
    @request = Request.find(params[:id])

    Rails.logger.info "=== UPDATE START ==="
    Rails.logger.info "Request ID: #{@request.id}"
    Rails.logger.info ""
    Rails.logger.info "=== PARAMS BRUTS REÇUS ==="
    Rails.logger.info "Tous les params: #{params.inspect}"
    Rails.logger.info ""
    Rails.logger.info "=== PARAMS REQUEST ==="
    Rails.logger.info "request params: #{params[:request]&.keys || 'nil'}"
    Rails.logger.info ""
    Rails.logger.info "=== RECHERCHE VALEURS FORMULAIRE ==="
    if params[:request]
      params[:request].each do |key, value|
        if key.to_s.include?('toiture') || key.to_s.include?('travaux')
          Rails.logger.info "  TROUVÉ: #{key} = #{value.inspect}"
        end
      end
    end
    Rails.logger.info ""
    Rails.logger.info "AVANT UPDATE - form_data existante:"
    @request.form_data&.each { |k, v| Rails.logger.info "  #{k}: #{v}" if k.to_s.include?('toiture') }

    # Gérer les brouillons pour la mise à jour aussi
    if params[:commit] == "Sauvegarder en brouillon"
      @request.status = 'draft'

      Rails.logger.info "=== TRAITEMENT PARAMETRES ==="
      Rails.logger.info "Params bruts reçus (toiture uniquement):"
      params[:request]&.each { |k, v| Rails.logger.info "  #{k}: #{v}" if k.to_s.include?('toiture') }

      # Assigner les nouvelles valeurs avec les données extraites
      processed_params = request_params.to_h  # Convertir en hash pour éviter UnfilteredParameters

      # S'assurer que form_data est aussi un hash normal
      if processed_params[:form_data].is_a?(ActionController::Parameters)
        processed_params[:form_data] = processed_params[:form_data].to_h
      end

      Rails.logger.info "=== APRÈS request_params ==="
      Rails.logger.info "processed_params keys: #{processed_params.keys}"
      Rails.logger.info "processed_params[:form_data] class: #{processed_params[:form_data].class}"
      Rails.logger.info "processed_params[:form_data] (toiture):"
      processed_params[:form_data]&.each { |k, v| Rails.logger.info "  #{k}: #{v}" if k.to_s.include?('toiture') }

      @request.assign_attributes(processed_params)
      @request.title = @request.title.present? ? @request.title : "Brouillon #{Time.current.strftime('%d/%m/%Y %H:%M')}"
      @request.description = @request.description.present? ? @request.description : "Brouillon en cours de rédaction"

      Rails.logger.info "=== APRÈS assign_attributes ==="
      Rails.logger.info "Form data dans @request (toiture):"
      @request.form_data&.each { |k, v| Rails.logger.info "  #{k}: #{v}" if k.to_s.include?('toiture') }

    elsif params[:commit] == "Créer la demande"
      processed_params = request_params.to_h  # Convertir en hash
      @request.assign_attributes(processed_params)
      @request.status = 'submitted'
    else
      processed_params = request_params
      @request.assign_attributes(processed_params)
    end

    save_result = @request.save

    Rails.logger.info "=== APRÈS SAVE ==="
    Rails.logger.info "Save result: #{save_result}"
    if save_result
      @request.reload
      Rails.logger.info "APRÈS RELOAD - form_data sauvegardée:"
      @request.form_data&.each { |k, v| Rails.logger.info "  #{k}: #{v}" if k.to_s.include?('toiture') }
    else
      Rails.logger.info "Erreurs save: #{@request.errors.full_messages}"
    end
    Rails.logger.info "=== UPDATE END ==="

    if save_result
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

    # Logique spécifique à la propriété selon son type
    case property.region&.downcase
    when 'bruxelles'
      if property.type_bien_bruxelles == 'entreprise'
        # Formulaires entreprises Bruxelles - UNIQUEMENT les 14 formulaires entreprise
        forms += [
          { id: :consultance_bruxelles, name: 'Consultance & Conseil', region: 'bruxelles', category: 'Conseil', eligible: true, description: 'Aide au conseil stratégique et opérationnel' },
          { id: :investissement_bruxelles, name: 'Investissement productif', region: 'bruxelles', category: 'Investissement', eligible: true, description: 'Soutien aux investissements matériels' },
          { id: :formation_bruxelles, name: 'Formation & Compétences', region: 'bruxelles', category: 'Formation', eligible: true, description: 'Développement des compétences' },
          { id: :recherche_bruxelles, name: 'Recherche & Développement', region: 'bruxelles', category: 'R&D', eligible: true, description: 'Innovation et développement technologique' },
          { id: :export_bruxelles, name: 'Export & International', region: 'bruxelles', category: 'Export', eligible: true, description: 'Développement international' },
          { id: :innovation_bruxelles, name: 'Innovation technologique', region: 'bruxelles', category: 'Innovation', eligible: true, description: 'Projets d\'innovation disruptive' },
          { id: :transition_bruxelles, name: 'Transition numérique', region: 'bruxelles', category: 'Digital', eligible: true, description: 'Digitalisation et transformation numérique' },
          { id: :accessibilite_bruxelles, name: 'Accessibilité & Inclusion', region: 'bruxelles', category: 'Social', eligible: true, description: 'Amélioration de l\'accessibilité' },
          { id: :achat_immobilier_bruxelles, name: 'Achat immobilier', region: 'bruxelles', category: 'Immobilier', eligible: true, description: 'Acquisition de biens immobiliers' },
          { id: :conformite_normes_bruxelles, name: 'Conformité aux normes', region: 'bruxelles', category: 'Conformité', eligible: true, description: 'Mise en conformité réglementaire' },
          { id: :digitalisation_bruxelles, name: 'Digitalisation avancée', region: 'bruxelles', category: 'Tech', eligible: true, description: 'Solutions digitales avancées' },
          { id: :formation_linguistique_bruxelles, name: 'Formation linguistique', region: 'bruxelles', category: 'Langues', eligible: true, description: 'Apprentissage des langues' },
          { id: :mobilite_retrofit_bruxelles, name: 'Mobilité & Retrofit', region: 'bruxelles', category: 'Mobilité', eligible: true, description: 'Solutions de mobilité durable' },
          { id: :recrutement_bruxelles, name: 'Recrutement & RH', region: 'bruxelles', category: 'RH', eligible: true, description: 'Aide au recrutement et gestion RH' }
        ]
      else
        # Formulaires particuliers Bruxelles - les 4 formulaires de rénovation
        forms += [
          { id: :regional_bruxelles, name: 'Prime régionale habitation', region: 'bruxelles', category: 'Rénovation', eligible: true },
          { id: :monuments_bruxelles, name: 'Monuments & Sites classés', region: 'bruxelles', category: 'Patrimoine', eligible: true },
          { id: :patrimoine_bruxelles, name: 'Petit patrimoine populaire', region: 'bruxelles', category: 'Patrimoine', eligible: true },
          { id: :communal_bruxelles, name: 'Primes communales', region: 'bruxelles', category: 'Communal', eligible: true }
        ]
      end
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
                                   # Paramètres Wallonie spécifiques manquants
                                   :type_demandeur, :qualite_demandeur, :numero_registre_national, :compte_bancaire,
                                   :adresse_demandeur, :code_postal_demandeur, :commune_demandeur, :pays_demandeur,
                                   :telephone_fixe, :telephone_mobile, :fax, :email_demandeur,
                                   :numero_bce, :denomination_sociale, :forme_juridique, :siege_social,
                                   :adresse_logement, :numero_logement, :code_postal_logement, :commune_logement,
                                   :numero_parcelle_cadastrale, :date_acquisition_bien, :personnes_charge, :revenus_globaux,
                                   :surface_plancher_chauffee, :affectation_bien, :annee_construction, :periode_travaux,
                                   :desamiantage, :ean_electricite, :ean_gaz, :date_pea,
                                   # Champs génériques travaux
                                   :travaux_isolation_toiture, :travaux_isolation_murs, :travaux_isolation_sols,
                                   :travaux_fenetres_portes, :travaux_chauffage_ecs, :travaux_ventilation,
                                   :travaux_energie_renouvelable, :travaux_etancheite, :travaux_autres,
                                   # Paramètres Flandre originaux
                                   :inkomen_gezin, :gezinssamenstelling, :type_renovatie, :eigenaar_bewoner, :kostprijs_werken,
                                   # Nouveaux paramètres Flandre optimisés
                                   :domicile, :registre_national, :nom, :prenom, :telephone, :email,
                                   :ean, :parcelle, :adresse, :code_postal, :commune, :type_bien, :usage,
                                   :chauffage_post_renovation, :travaux_toiture, :travaux_murs, :travaux_sol,
                                   :travaux_vitrage, :travaux_chauffage, :travaux_complementaires, :travaux_ventilation,
                                   :travaux_solaire, :revenus_annuels, :annee_aer, :compte_bancaire,
                                   :email_contact, :telephone_contact, :confirmation_veracite, :acceptation_conditions,
                                   # Paramètres profil demandeur et patrimoine
                                   :profil_demandeur, :travaux_amiante, :type_chauffage, :type_ventilation, :performance_vitrage,
                                   # Champs applicant (demandeur)
                                   :applicant_title, :applicant_type, :applicant_firstname, :applicant_lastname, :applicant_organization,
                                   :applicant_address, :applicant_number, :applicant_postal_code, :applicant_city,
                                   :applicant_phone, :applicant_email, :applicant_national_number,
                                   # Champs heritage (patrimoine)
                                   :heritage_address, :heritage_number, :heritage_postal_code, :heritage_city,
                                   :heritage_protection_id, :heritage_type, :heritage_description,
                                   # Champs work (travaux)
                                   :work_type, :work_description, :work_start_date, :work_end_date, :work_cost_estimate,
                                   :requested_premium_percentage,
                                   # Champs declaration
                                   :declaration_owner, :declaration_accuracy, :declaration_conditions, :declaration_no_start, :declaration_quality,
                                   :signature_place, :signature_date,
                                   # Champs détaillés pour isolation toiture
                                   :surface_toiture, :methode_toiture, :date_placement_toiture, :materiau_toiture, :marque_toiture, :type_isolation_toiture,
                                   # Champs détaillés pour isolation murs
                                   :surface_murs, :methode_murs, :date_placement_murs, :materiau_murs, :marque_murs, :type_isolation_murs,
                                   # Champs détaillés pour isolation sol
                                   :surface_sol, :methode_sol, :date_placement_sol, :materiau_sol, :marque_sol, :type_isolation_sol,
                                   # Champs détaillés pour vitrage
                                   :surface_vitrage, :type_vitrage, :date_placement_vitrage, :marque_vitrage,
                                   # Champs détaillés pour chauffage
                                   :type_systeme_chauffage, :date_placement_chauffage, :marque_chauffage,
                                   # Champs détaillés pour ventilation
                                   :type_systeme_ventilation, :date_placement_ventilation, :marque_ventilation,
                                   # Champs détaillés pour travaux complémentaires
                                   :description_complementaires,
                                   # Champs pour désamiantage
                                   :localisation_desamiantage,
                                   # Support pour les fichiers
                                   :document_devis, :document_factures, :document_aer, :document_peb,
                                   :document_attestations, :document_photos, :document_autres,
                                   document_devis: [], document_factures: [], document_attestations: [], document_photos: [], document_autres: [], documents: [])

    Rails.logger.info "=== REQUEST_PARAMS DEBUG ==="
    Rails.logger.info "Permitted params keys: #{permitted_params.keys}"
    Rails.logger.info "Title: #{permitted_params[:title]}"
    Rails.logger.info "Form type: #{permitted_params[:form_type]}"
    Rails.logger.info "Region: #{permitted_params[:region]}"
    Rails.logger.info "Property ID: #{permitted_params[:property_id]}"
    Rails.logger.info "Surface toiture direct: #{permitted_params[:surface_toiture]}"
    Rails.logger.info "Marque toiture direct: #{permitted_params[:marque_toiture]}"

    # Extraire les données de formulaire et les stocker dans form_data
    result = extract_form_data_from_params(permitted_params)

    Rails.logger.info "REQUEST_PARAMS result keys: #{result.keys}"
    Rails.logger.info "REQUEST_PARAMS result form_data: #{result[:form_data]&.slice('surface_toiture', 'marque_toiture', 'travaux_toiture')}"

    result
  end

  def extract_form_data_from_params(permitted_params)
    # Champs de base du modèle Request (ne vont pas dans form_data)
    base_fields = [:title, :description, :status, :region, :property_id, :form_type, :template_version]

    # Champs de fichiers (ne vont pas dans form_data)
    file_fields = [:document_devis, :document_factures, :document_aer, :document_peb,
                   :document_attestations, :document_photos, :document_autres]

    # Extraire les données de formulaire (tous les autres champs)
    form_data_fields = permitted_params.except(*base_fields, *file_fields).reject { |k, v| v.blank? }

    Rails.logger.info "=== EXTRACT_FORM_DATA DEBUG ==="
    Rails.logger.info "Form data fields extracted: #{form_data_fields.keys}"
    Rails.logger.info "Surface toiture: #{form_data_fields[:surface_toiture] || form_data_fields['surface_toiture']}"
    Rails.logger.info "Marque toiture: #{form_data_fields[:marque_toiture] || form_data_fields['marque_toiture']}"
    Rails.logger.info "Travaux toiture: #{form_data_fields[:travaux_toiture] || form_data_fields['travaux_toiture']}"

    # CORRECTION: Fusionner avec les données existantes au lieu d'écraser
    if form_data_fields.present?
      # Pour une mise à jour (requête existante)
      request_id = params[:id]
      if request_id && Request.exists?(request_id)
        current_request = Request.find(request_id)
        existing_form_data = current_request&.form_data || {}

        Rails.logger.info "=== FUSION FORM_DATA (MISE À JOUR) ==="
        Rails.logger.info "Request ID for fusion: #{request_id}"
        Rails.logger.info "Existing form_data keys: #{existing_form_data.keys.size}"
        Rails.logger.info "New form_data keys: #{form_data_fields.keys.size}"

        # Fusionner au lieu d'écraser
        merged_form_data = existing_form_data.merge(form_data_fields.stringify_keys)
        permitted_params[:form_data] = merged_form_data

        Rails.logger.info "Merged form_data keys: #{merged_form_data.keys.size}"
        Rails.logger.info "Surface après fusion: #{merged_form_data['surface_toiture']}"
        Rails.logger.info "Marque après fusion: #{merged_form_data['marque_toiture']}"
      else
        # Nouveau request - utiliser directement les données du formulaire
        permitted_params[:form_data] = form_data_fields.stringify_keys
        Rails.logger.info "=== NOUVEAU REQUEST - PAS DE FUSION ==="
        Rails.logger.info "New request form_data keys: #{form_data_fields.keys.size}"
        Rails.logger.info "Surface nouveau: #{form_data_fields[:surface_toiture] || form_data_fields['surface_toiture']}"
        Rails.logger.info "Marque nouveau: #{form_data_fields[:marque_toiture] || form_data_fields['marque_toiture']}"
      end
    else
      Rails.logger.info "=== AUCUNE DONNÉE FORM_DATA ==="
    end

    # Retourner seulement les champs de base + form_data + fichiers
    result = permitted_params.slice(*base_fields, *file_fields, :form_data)

    # IMPORTANT: Convertir tout en hash ordinaire pour éviter UnfilteredParameters
    result = result.to_h
    if result[:form_data].is_a?(ActionController::Parameters)
      result[:form_data] = result[:form_data].to_h
    end

    Rails.logger.info "Final result form_data: #{result[:form_data]&.slice('surface_toiture', 'marque_toiture', 'travaux_toiture')}"

    result
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
      parcelle: property.numero_cadastre,
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

  def debug_export
    @request = Request.find(params[:id])

    # Vérification de sécurité
    unless @request.user == current_user || current_user&.admin?
      redirect_to requests_path, alert: "Vous n'avez pas accès à cette demande."
      return
    end
  end
end
