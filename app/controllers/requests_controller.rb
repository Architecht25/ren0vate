class RequestsController < ApplicationController
  # Utiliser null_session au lieu de exception pour la protection CSRF
  # Cela permet de continuer même si le token est invalide
  protect_from_forgery with: :null_session, only: [:update, :autosave]

  # Gérer les erreurs de token CSRF expirés pour les autres actions
  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    Rails.logger.warn "⚠️ Token CSRF invalide - Session expirée ou page périmée"

    # Pour les requêtes de sauvegarde, sauvegarder les données dans la session et rediriger
    if params[:commit] == "Sauvegarder en brouillon" && params[:request].present?
      session[:pending_request_data] = params[:request].to_unsafe_h
      session[:pending_request_id] = params[:id]

      flash[:warning] = "⚠️ Votre session a expiré. Veuillez recharger la page et réessayer. Vos données ont été temporairement sauvegardées."
      redirect_to params[:id].present? ? edit_request_path(params[:id]) : new_request_path
    else
      flash[:alert] = "Votre session a expiré. Veuillez vous reconnecter."
      redirect_to new_user_session_path
    end
  end

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

    @request = current_user.requests.find(params[:id])
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

          # URL selon la région et le type de formulaire
          official_url = case @request.region
                        when 'flandre'
                          'https://www.vlaanderen.be/premies-pour-renovation/mijn-verbouwpremie'
                        when 'wallonie'
                          'https://energie.wallonie.be/fr/aides-et-primes.html?IDC=10717'
                        when 'bruxelles'
                          if @request.form_type == 'monuments_bruxelles'
                            'https://monument.heritage.brussels/fr/formulaire-de-demande/'
                          else
                            'https://www.brussels.be/logement-et-energie/renovation-de-mon-logement/primes'
                          end
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
    @request = current_user.requests.find(params[:id])

    # Restaurer les données temporaires de la session si elles existent (après erreur CSRF)
    if session[:pending_request_data].present? && session[:pending_request_id].to_s == params[:id].to_s
      @pending_data = session[:pending_request_data]
      session.delete(:pending_request_data)
      session.delete(:pending_request_id)
      flash.now[:info] = "💾 Vos données non sauvegardées ont été restaurées. Vous pouvez continuer votre saisie."
    end

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
      @form_data = base_form_data.stringify_keys.merge(@request.form_data)
      Rails.logger.info "=== EDIT - FUSION FORM_DATA ==="
      Rails.logger.info "Base form_data keys: #{base_form_data.keys.size}"
      Rails.logger.info "Request form_data keys: #{@request.form_data.keys.size}"
      Rails.logger.info "Merged form_data keys: #{@form_data.keys.size}"
      Rails.logger.info "Surface toiture in @form_data: #{@form_data['surface_toiture'] || '[nil]'}"
      Rails.logger.info "Marque toiture in @form_data: #{@form_data['marque_toiture'] || '[nil]'}"
      Rails.logger.info "Travaux toiture in @form_data: #{@form_data['travaux_toiture'] || '[nil]'}"
      Rails.logger.info "Date raccordement in @form_data: #{@form_data['date_raccordement_electricite'] || '[nil]'}"
    else
      @form_data = base_form_data.stringify_keys
      Rails.logger.info "=== EDIT - PAS DE FORM_DATA EXISTANTE ==="
    end

    # Normaliser les champs Flandre qui peuvent avoir des valeurs héritées de la propriété
    # (ex: type_bien stocké comme 'maison' mais les radio buttons attendent 'maison_unifamiliale')
    if @request.region == 'flandre'
      case @form_data['type_bien']
      when 'maison' then @form_data['type_bien'] = 'maison_unifamiliale'
      when 'appartement_copro' then @form_data['type_bien'] = 'appartement'
      when 'immeuble_appartements' then @form_data['type_bien'] = 'immeuble'
      end

      dre = @form_data['date_raccordement_electricite']
      if dre.present? && !['avant_2006', 'apres_2006'].include?(dre.to_s)
        year = dre.to_i
        @form_data['date_raccordement_electricite'] = year < 2006 ? 'avant_2006' : 'apres_2006' if year > 0
      end
    end

    # CRUCIAL: Créer un objet virtuel qui combine @request avec les données de form_data
    # pour que Rails puisse pré-remplir les champs du formulaire
    form_data_safe = @form_data || {}

    # Méthodes pour les données du bien
    @request.define_singleton_method(:date_raccordement_electricite) { form_data_safe['date_raccordement_electricite'] }
    @request.define_singleton_method(:adresse) { form_data_safe['adresse'] }
    @request.define_singleton_method(:numero) { form_data_safe['numero'] }
    @request.define_singleton_method(:rue) { form_data_safe['rue'] }
    @request.define_singleton_method(:code_postal) { form_data_safe['code_postal'] }
    @request.define_singleton_method(:commune) { form_data_safe['commune'] }
    @request.define_singleton_method(:type_bien) { form_data_safe['type_bien'] }
    @request.define_singleton_method(:usage) { form_data_safe['usage'] }
    @request.define_singleton_method(:chauffage_post_renovation) { form_data_safe['chauffage_post_renovation'] }

    @request.define_singleton_method(:surface_toiture) { form_data_safe['surface_toiture'] }
    @request.define_singleton_method(:marque_toiture) { form_data_safe['marque_toiture'] }
    @request.define_singleton_method(:methode_toiture) { form_data_safe['methode_toiture'] }
    @request.define_singleton_method(:date_placement_toiture) { form_data_safe['date_placement_toiture'] }
    @request.define_singleton_method(:materiau_toiture) { form_data_safe['materiau_toiture'] }
    @request.define_singleton_method(:type_isolation_toiture) { form_data_safe['type_isolation_toiture'] }
    @request.define_singleton_method(:epaisseur_materiau_toiture) { form_data_safe['epaisseur_materiau_toiture'] }
    @request.define_singleton_method(:valeur_rd_toiture) { form_data_safe['valeur_rd_toiture'] }

    # Ajouter les méthodes pour les murs
    @request.define_singleton_method(:surface_murs) { form_data_safe['surface_murs'] }
    @request.define_singleton_method(:marque_murs) { form_data_safe['marque_murs'] }
    @request.define_singleton_method(:methode_murs) { form_data_safe['methode_murs'] }
    @request.define_singleton_method(:date_placement_murs) { form_data_safe['date_placement_murs'] }
    @request.define_singleton_method(:materiau_murs) { form_data_safe['materiau_murs'] }
    @request.define_singleton_method(:type_isolation_murs) { form_data_safe['type_isolation_murs'] }
    @request.define_singleton_method(:epaisseur_materiau_murs) { form_data_safe['epaisseur_materiau_murs'] }
    @request.define_singleton_method(:valeur_rd_murs) { form_data_safe['valeur_rd_murs'] }
    @request.define_singleton_method(:nombre_couches_murs) { form_data_safe['nombre_couches_murs'] }

    # Ajouter les méthodes pour le sol
    @request.define_singleton_method(:surface_sol) { form_data_safe['surface_sol'] }
    @request.define_singleton_method(:marque_sol) { form_data_safe['marque_sol'] }
    @request.define_singleton_method(:methode_sol) { form_data_safe['methode_sol'] }
    @request.define_singleton_method(:date_placement_sol) { form_data_safe['date_placement_sol'] }
    @request.define_singleton_method(:materiau_sol) { form_data_safe['materiau_sol'] }
    @request.define_singleton_method(:type_isolation_sol) { form_data_safe['type_isolation_sol'] }
    @request.define_singleton_method(:epaisseur_materiau_sol) { form_data_safe['epaisseur_materiau_sol'] }
    @request.define_singleton_method(:valeur_rd_sol) { form_data_safe['valeur_rd_sol'] }

    # Ajouter les méthodes pour la cave
    @request.define_singleton_method(:surface_cave) { form_data_safe['surface_cave'] }
    @request.define_singleton_method(:marque_cave) { form_data_safe['marque_cave'] }
    @request.define_singleton_method(:date_placement_cave) { form_data_safe['date_placement_cave'] }
    @request.define_singleton_method(:materiau_cave) { form_data_safe['materiau_cave'] }
    @request.define_singleton_method(:type_isolation_cave) { form_data_safe['type_isolation_cave'] }
    @request.define_singleton_method(:epaisseur_materiau_cave) { form_data_safe['epaisseur_materiau_cave'] }
    @request.define_singleton_method(:valeur_rd_cave) { form_data_safe['valeur_rd_cave'] }

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
    @request = current_user.requests.find(params[:id])

    # DÉBOGAGE SIMPLE - Écrire dans un fichier pour être sûr de voir les données
    debug_file = Rails.root.join('log', 'wallonie_debug.log')
    File.open(debug_file, 'a') do |f|
      f.puts "=" * 80
      f.puts "UPDATE appelé à #{Time.current}"
      f.puts "Request ID: #{params[:id]}"
      f.puts "Commit: #{params[:commit]}"
      f.puts "-" * 40
      f.puts "Title reçu: #{params[:request]&.[](:title).inspect}"
      f.puts "Maintien régime reçu: #{params[:request]&.[](:maintien_regime).inspect}"
      f.puts "-" * 40
      f.puts "Checkbox travaux reçues:"
      params[:request]&.each do |k, v|
        if k.to_s.start_with?('travaux_')
          f.puts "  #{k}: #{v.inspect}"
        end
      end
      f.puts "=" * 80
    end

    Rails.logger.info "=== UPDATE START ==="
    Rails.logger.info "Request ID: #{@request.id}"
    Rails.logger.info ""
    Rails.logger.info "=== PARAMS BRUTS REÇUS ==="
    Rails.logger.info "Title dans params[:request]: #{params[:request]&.[](:title)}"
    Rails.logger.info "Maintien regime: #{params[:request]&.[](:maintien_regime)}"
    Rails.logger.info ""
    Rails.logger.info "=== PARAMS REQUEST (CHECKBOX TRAVAUX) ==="
    if params[:request]
      params[:request].each do |key, value|
        if key.to_s.include?('travaux_') && key.to_s.include?('remplacement')
          Rails.logger.info "  #{key} = #{value.inspect}"
        end
      end
    end
    Rails.logger.info ""
    Rails.logger.info "AVANT UPDATE - Title actuel: #{@request.title}"
    Rails.logger.info "AVANT UPDATE - form_data.keys: #{@request.form_data&.keys&.size || 0}"

    # Gérer les brouillons pour la mise à jour aussi
    if params[:commit] == "Sauvegarder en brouillon"
      @request.status = 'draft'

      # TEST SIMPLE - Sauvegarder directement le titre sans passer par request_params
      if params[:request][:title].present?
        @request.title = params[:request][:title]
        Rails.logger.info "✅ TITLE ASSIGNÉ DIRECTEMENT: #{@request.title}"
      end

      Rails.logger.info "=== TRAITEMENT PARAMETRES ==="
      Rails.logger.info "Params bruts reçus (checkbox travaux):"
      params[:request]&.each { |k, v| Rails.logger.info "  #{k}: #{v}" if k.to_s.start_with?('travaux_remplacement') }

      # Assigner les nouvelles valeurs avec les données extraites
      processed_params = request_params.to_h  # Convertir en hash pour éviter UnfilteredParameters

      # S'assurer que form_data est aussi un hash normal
      if processed_params[:form_data].is_a?(ActionController::Parameters)
        processed_params[:form_data] = processed_params[:form_data].to_h
      end

      Rails.logger.info "=== APRÈS request_params ==="
      Rails.logger.info "processed_params keys: #{processed_params.keys}"
      Rails.logger.info "processed_params[:title]: #{processed_params[:title].inspect}"
      Rails.logger.info "processed_params[:form_data] présent?: #{processed_params[:form_data].present?}"
      if processed_params[:form_data].present?
        Rails.logger.info "processed_params[:form_data] keys: #{processed_params[:form_data].keys.size}"
        Rails.logger.info "Title dans form_data?: #{processed_params[:form_data]['title'] || processed_params[:form_data][:title]}"
      end

      @request.assign_attributes(processed_params)
      # Ne définir un titre par défaut QUE si le titre n'a pas été assigné
      if @request.title.blank?
        @request.title = "Brouillon #{Time.current.strftime('%d/%m/%Y %H:%M')}"
      end
      if @request.description.blank?
        @request.description = "Brouillon en cours de rédaction"
      end

      Rails.logger.info "=== APRÈS assign_attributes ==="
      Rails.logger.info "Title après assign: #{@request.title}"
      Rails.logger.info "Form data dans @request.form_data.keys: #{@request.form_data&.keys&.size || 0}"
      Rails.logger.info "Maintien regime dans form_data: #{@request.form_data&.[]('maintien_regime')}"
      Rails.logger.info "Travaux checkbox dans form_data:"
      @request.form_data&.each { |k, v| Rails.logger.info "  #{k}: #{v}" if k.to_s.include?('travaux_remplacement') }

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
      Rails.logger.info "APRÈS RELOAD - Title: #{@request.title}"
      Rails.logger.info "APRÈS RELOAD - form_data.keys: #{@request.form_data&.keys&.size || 0}"
      Rails.logger.info "APRÈS RELOAD - Maintien regime: #{@request.form_data&.[]('maintien_regime')}"
      Rails.logger.info "APRÈS RELOAD - Travaux checkbox:"
      @request.form_data&.each { |k, v| Rails.logger.info "  #{k}: #{v}" if k.to_s.include?('travaux_remplacement') }
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
                        if @request.form_type == 'monuments_bruxelles'
                          'https://monument.heritage.brussels/fr/formulaire-de-demande/'
                        else
                          'https://www.brussels.be/logement-et-energie/renovation-de-mon-logement/primes'
                        end
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

    # Filtrer les paramètres pour l'auto-save : uniquement les champs métier du formulaire
    # (exclut user_id, property_id, status, region pour éviter toute escalade de privilege)
    autosave_params = params.require(:request).permit(
      :title, :description, :form_type, :template_version, :form_data,
      :revenus_menage, :nombre_personnes, :type_travaux, :surface_travaux, :cout_estime,
      :revenus_reference, :composition_menage, :categories_travaux, :logement_principal, :montant_travaux,
      :numero_audit, :date_audit, :numero_agrement_auditeur, :nom_auditeur, :adresse_auditeur,
      :date_enregistrement_audit, :type_demandeur, :qualite_demandeur, :numero_registre_national,
      :compte_bancaire, :adresse_demandeur, :code_postal_demandeur, :commune_demandeur, :pays_demandeur,
      :numero_demandeur, :date_naissance, :telephone_fixe, :telephone_mobile, :fax, :email_demandeur,
      :numero_bce, :denomination_sociale, :forme_juridique, :siege_social,
      :adresse_logement, :numero_logement, :code_postal_logement, :commune_logement,
      :numero_parcelle_cadastrale, :date_acquisition_bien, :personnes_charge, :revenus_globaux,
      :surface_plancher_chauffee, :affectation_bien, :annee_construction, :periode_travaux,
      :desamiantage, :ean_electricite, :ean_gaz, :date_pea,
      :maintien_regime, :adresse_contact_identique, :type_compte_bancaire, :localisation_travaux,
      :type_logement, :acces_donnees_revenu, :condition_occupation,
      :declaration_traitement_automatise,
      :travaux_isolation_toiture, :travaux_isolation_murs, :travaux_isolation_sols,
      :travaux_fenetres_portes, :travaux_chauffage_ecs, :travaux_ventilation,
      :travaux_energie_renouvelable, :travaux_etancheite, :travaux_autres,
      :inkomen_gezin, :gezinssamenstelling, :type_renovatie, :eigenaar_bewoner, :kostprijs_werken,
      :domicile, :registre_national, :nom, :prenom, :telephone, :email,
      :ean, :parcelle, :adresse, :numero, :rue, :code_postal, :commune, :type_bien, :usage,
      :chauffage_post_renovation, :travaux_toiture, :travaux_murs, :travaux_sol,
      :travaux_vitrage, :travaux_chauffage, :travaux_complementaires, :travaux_ventilation,
      :travaux_solaire, :revenus_annuels, :annee_aer,
      :email_contact, :telephone_contact, :confirmation_veracite, :acceptation_conditions,
      :profil_demandeur, :travaux_amiante, :type_chauffage, :type_ventilation, :performance_vitrage,
      :applicant_title, :applicant_type, :applicant_firstname, :applicant_lastname, :applicant_organization,
      :applicant_address, :applicant_number, :applicant_postal_code, :applicant_city,
      :applicant_phone, :applicant_email, :applicant_national_number,
      :heritage_address, :heritage_number, :heritage_postal_code, :heritage_city,
      :heritage_protection_id, :heritage_type, :heritage_description,
      :work_type, :work_description, :work_start_date, :work_end_date, :work_cost_estimate,
      :requested_premium_percentage,
      :declaration_owner, :declaration_accuracy, :declaration_conditions, :declaration_no_start, :declaration_quality,
      :signature_place, :signature_date,
      :surface_toiture, :methode_toiture, :date_placement_toiture, :materiau_toiture, :marque_toiture, :type_isolation_toiture,
      :epaisseur_materiau_toiture, :valeur_rd_toiture,
      :surface_murs, :methode_murs, :date_placement_murs, :materiau_murs, :marque_murs, :type_isolation_murs,
      :epaisseur_materiau_murs, :valeur_rd_murs, :nombre_couches_murs,
      :facade_avant, :facade_arriere, :facade_gauche, :facade_droite,
      :surface_sol, :methode_sol, :date_placement_sol, :materiau_sol, :marque_sol, :type_isolation_sol,
      :epaisseur_materiau_sol, :valeur_rd_sol,
      :travaux_cave, :surface_cave, :date_placement_cave, :materiau_cave, :marque_cave, :type_isolation_cave,
      :epaisseur_materiau_cave, :valeur_rd_cave,
      :surface_vitrage, :type_vitrage, :date_placement_vitrage, :marque_vitrage,
      :valeur_ug_vitrage, :vitrage_simple, :vitrage_double, :vitrage_simple_double,
      :nouvelles_fenetres_pieces_seches, :hoogrendement_bevestiging, :vergunningsplichtig,
      :travaux_portes, :surface_portes, :date_placement_portes, :type_portes, :marque_portes,
      :valeur_u_portes, :ouvertures_pieces_humides,
      :type_systeme_chauffage, :date_placement_chauffage, :marque_chauffage,
      :remplacement_chauffage_electrique, :raccordement_gaz,
      :marque_pac_geo, :type_pac_geo, :puissance_thermique_geo, :puissance_electrique_geo,
      :puissance_gaz_geo, :label_europeen_geo,
      :marque_pac_air_eau, :type_pac_air_eau, :puissance_thermique_air_eau, :puissance_electrique_air_eau,
      :puissance_gaz_air_eau, :label_europeen_air_eau,
      :marque_pac_air_air, :type_pac_air_air, :puissance_thermique_air_air, :puissance_electrique_air_air,
      :puissance_gaz_air_air, :label_europeen_air_air,
      :marque_pac_hybride, :type_pac_hybride, :puissance_thermique_hybride, :puissance_electrique_hybride,
      :puissance_gaz_hybride, :label_europeen_hybride,
      :puissance_electrique_boiler, :puissance_thermique_boiler, :label_europeen_boiler,
      :type_systeme_ventilation, :date_placement_ventilation, :marque_ventilation,
      :description_complementaires, :localisation_desamiantage, :date_raccordement_electricite
    ).to_h

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
        { id: :monuments_bruxelles, name: 'Monuments & Sites classés', subtitle: 'Monument.brussels', region: 'bruxelles', category: 'Patrimoine' },
        { id: :patrimoine_bruxelles, name: 'Petit patrimoine populaire', subtitle: 'Bruxelles Environnement', region: 'bruxelles', category: 'Patrimoine' },
        { id: :communal_bruxelles, name: 'Primes communales', subtitle: 'Commune', region: 'bruxelles', category: 'Communal' }
      ]

      # Formulaires Wallonie
      forms += [
        { id: :regional_wallonie, name: 'Prime régionale habitation', subtitle: 'MyRenovation – SPW', region: 'wallonie', category: 'Rénovation' },
        { id: :audit_wallonie, name: 'Audit énergétique', subtitle: 'Audit logement – SPW', region: 'wallonie', category: 'Audit' },
        { id: :monuments_wallonie, name: 'Monuments & Sites classés', subtitle: 'AWaP – Patrimoine', region: 'wallonie', category: 'Patrimoine' },
        { id: :communal_wallonie, name: 'Primes communales', subtitle: 'Commune', region: 'wallonie', category: 'Communal' }
      ]

      # Formulaires Flandre
      forms += [
        { id: :regional_flandre, name: 'Prime régionale habitation', subtitle: 'Mijn VerbouwPremie', region: 'flandre', category: 'Rénovation' },
        { id: :monuments_flandre, name: 'Monuments & Sites', subtitle: 'Onroerend Erfgoed', region: 'flandre', category: 'Patrimoine' },
        { id: :communal_flandre, name: 'Primes communales', subtitle: 'Gemeente', region: 'flandre', category: 'Communal' }
      ]

      return forms
    end

    # Logique spécifique à la propriété selon son type
    case property.region&.downcase
    when 'bruxelles'
      if property.type_bien_bruxelles == 'entreprise'
        # Formulaires entreprises Bruxelles - Les 14 formulaires correspondant aux partials existants
        forms += [
          { id: :consultance_bruxelles, name: 'Consultance & Conseil', region: 'bruxelles', category: 'Conseil', eligible: true, description: 'Aide au conseil stratégique et opérationnel' },
          { id: :investissement_bruxelles, name: 'Investissements généraux', region: 'bruxelles', category: 'Investissement', eligible: true, description: 'Soutien aux investissements matériels généraux' },
          { id: :formation_bruxelles, name: 'Formation & Compétences', region: 'bruxelles', category: 'Formation', eligible: true, description: 'Développement des compétences' },
          { id: :recrutement_bruxelles, name: 'Recrutement & RH', region: 'bruxelles', category: 'RH', eligible: true, description: 'Aide au recrutement et gestion RH' },
          { id: :digitalisation_bruxelles, name: 'Digitalisation avancée', region: 'bruxelles', category: 'Tech', eligible: true, description: 'Solutions digitales avancées' },
          { id: :accessibilite_bruxelles, name: 'Accessibilité & Inclusion', region: 'bruxelles', category: 'Social', eligible: true, description: 'Amélioration de l\'accessibilité' },
          { id: :achat_immobilier_bruxelles, name: 'Achat immobilier', region: 'bruxelles', category: 'Immobilier', eligible: true, description: 'Acquisition de biens immobiliers' },
          { id: :conformite_normes_bruxelles, name: 'Conformité aux normes', region: 'bruxelles', category: 'Conformité', eligible: true, description: 'Mise en conformité réglementaire' },
          { id: :mobilite_retrofit_bruxelles, name: 'Mobilité & Retrofit', region: 'bruxelles', category: 'Mobilité', eligible: true, description: 'Retrofit et transformation de véhicules' },
          { id: :consultance_transition_bruxelles, name: 'Consultance Transition', region: 'bruxelles', category: 'Transition', eligible: true, description: 'Accompagnement à la transition écologique' },
          { id: :investissement_transition_bruxelles, name: 'Investissement Transition', region: 'bruxelles', category: 'Transition', eligible: true, description: 'Investissements pour la transition écologique' },
          { id: :mobilite_velo_cargo_bruxelles, name: 'Vélo Cargo', region: 'bruxelles', category: 'Mobilité', eligible: true, description: 'Acquisition de vélos cargo' },
          { id: :mobilite_utilistaire_electrique_bruxelles, name: 'Véhicule Utilitaire Électrique', region: 'bruxelles', category: 'Mobilité', eligible: true, description: 'Acquisition de véhicules utilitaires électriques' },
          { id: :securisation_bruxelles, name: 'Sécurisation', region: 'bruxelles', category: 'Sécurité', eligible: true, description: 'Sécurisation des locaux et équipements' }
        ]
      else
        # Formulaires particuliers Bruxelles - les 3 formulaires de rénovation
        forms += [
          { id: :monuments_bruxelles, name: 'Monuments & Sites classés', subtitle: 'Monument.brussels', region: 'bruxelles', category: 'Patrimoine', eligible: true },
          { id: :patrimoine_bruxelles, name: 'Petit patrimoine populaire', subtitle: 'Bruxelles Environnement', region: 'bruxelles', category: 'Patrimoine', eligible: true },
          { id: :communal_bruxelles, name: 'Primes communales', subtitle: 'Commune', region: 'bruxelles', category: 'Communal', eligible: true }
        ]
      end
    when 'wallonie'
      forms += [
        { id: :regional_wallonie, name: 'Prime régionale habitation', subtitle: 'MyRenovation – SPW', region: 'wallonie', category: 'Rénovation', eligible: true },
        { id: :audit_wallonie, name: 'Audit énergétique', subtitle: 'Audit logement – SPW', region: 'wallonie', category: 'Audit', eligible: true },
        { id: :monuments_wallonie, name: 'Monuments & Sites classés', subtitle: 'AWaP – Patrimoine', region: 'wallonie', category: 'Patrimoine', eligible: true },
        { id: :communal_wallonie, name: 'Primes communales', subtitle: 'Commune', region: 'wallonie', category: 'Communal', eligible: true }
      ]
    when 'flandre'
      forms += [
        { id: :regional_flandre, name: 'Prime régionale habitation', subtitle: 'Mijn VerbouwPremie', region: 'flandre', category: 'Rénovation', eligible: true },
        { id: :monuments_flandre, name: 'Monuments & Sites', subtitle: 'Onroerend Erfgoed', region: 'flandre', category: 'Patrimoine', eligible: true },
        { id: :communal_flandre, name: 'Primes communales', subtitle: 'Gemeente', region: 'flandre', category: 'Communal', eligible: true }
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
                                   :date_enregistrement_audit,
                                   # Paramètres Wallonie spécifiques manquants
                                   :type_demandeur, :qualite_demandeur, :numero_registre_national, :compte_bancaire,
                                   :adresse_demandeur, :code_postal_demandeur, :commune_demandeur, :pays_demandeur,
                                   :numero_demandeur, :date_naissance,
                                   :telephone_fixe, :telephone_mobile, :fax, :email_demandeur,
                                   :numero_bce, :denomination_sociale, :forme_juridique, :siege_social,
                                   :adresse_logement, :numero_logement, :code_postal_logement, :commune_logement,
                                   :numero_parcelle_cadastrale, :date_acquisition_bien, :personnes_charge, :revenus_globaux,
                                   :surface_plancher_chauffee, :affectation_bien, :annee_construction, :periode_travaux,
                                   :desamiantage, :ean_electricite, :ean_gaz, :date_pea,
                                   # Boutons radio Wallonie
                                   :maintien_regime, :adresse_contact_identique, :type_compte_bancaire, :localisation_travaux,
                                   :type_logement, :acces_donnees_revenu, :condition_occupation,
                                   # Checkbox travaux Wallonie
                                   :travaux_remplacement_couverture, :travaux_appropriation_charpente, :travaux_dispositif_eaux_pluviales,
                                   :travaux_isolation_toit_combles, :travaux_assechement_infiltrations, :travaux_assechement_humidite,
                                   :travaux_renforcement_murs, :travaux_isolation_murs, :travaux_remplacement_supports, :travaux_isolation_sols,
                                   :travaux_appropriation_electrique, :travaux_appropriation_gaz, :travaux_elimination_merule,
                                   :travaux_elimination_radon, :travaux_remplacement_menuiseries,
                                   :travaux_pompe_chaleur_ecs_exclusive, :travaux_pompe_chaleur_chauffage_combinee,
                                   :travaux_chaudiere_biomasse, :travaux_poele_biomasse, :travaux_chauffe_eau_solaire,
                                   :travaux_ventilation_simple_flux_ensemble, :travaux_ventilation_double_flux_ensemble,
                                   :travaux_ventilation_simple_flux_partie, :travaux_ventilation_double_flux_partie,
                                   :travaux_isolation_conduites_chauffage_hors_volume, :travaux_isolation_ballon_stockage_chauffage,
                                   :travaux_circulateurs_vitesse_variable, :travaux_remplacement_ballon_stockage_chauffage,
                                   :travaux_vannes_thermostatiques, :travaux_thermostat_ambiance,
                                   :travaux_remplacement_reservoir_ecs, :travaux_isolation_conduites_boucle_ecs,
                                   :travaux_isolation_echangeur_plaques, :travaux_isolation_ballon_stockage_ecs,
                                   # Checkbox déclarations
                                   :declaration_traitement_automatise,
                                   # Champs génériques travaux
                                   :travaux_isolation_toiture, :travaux_isolation_murs, :travaux_isolation_sols,
                                   :travaux_fenetres_portes, :travaux_chauffage_ecs, :travaux_ventilation,
                                   :travaux_energie_renouvelable, :travaux_etancheite, :travaux_autres,
                                   # Paramètres Flandre originaux
                                   :inkomen_gezin, :gezinssamenstelling, :type_renovatie, :eigenaar_bewoner, :kostprijs_werken,
                                   # Nouveaux paramètres Flandre optimisés
                                   :domicile, :registre_national, :nom, :prenom, :telephone, :email,
                                   :ean, :parcelle, :adresse, :numero, :rue, :code_postal, :commune, :type_bien, :usage,
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
                                   :epaisseur_materiau_toiture, :valeur_rd_toiture,
                                   # Champs détaillés pour isolation murs
                                   :surface_murs, :methode_murs, :date_placement_murs, :materiau_murs, :marque_murs, :type_isolation_murs,
                                   :epaisseur_materiau_murs, :valeur_rd_murs, :nombre_couches_murs,
                                   :facade_avant, :facade_arriere, :facade_gauche, :facade_droite,
                                   # Champs détaillés pour isolation sol
                                   :surface_sol, :methode_sol, :date_placement_sol, :materiau_sol, :marque_sol, :type_isolation_sol,
                                   :epaisseur_materiau_sol, :valeur_rd_sol,
                                   # Champs détaillés pour isolation cave
                                   :travaux_cave, :surface_cave, :date_placement_cave, :materiau_cave, :marque_cave, :type_isolation_cave,
                                   :epaisseur_materiau_cave, :valeur_rd_cave,
                                   # Champs détaillés pour vitrage
                                   :surface_vitrage, :type_vitrage, :date_placement_vitrage, :marque_vitrage,
                                   :valeur_ug_vitrage, :vitrage_simple, :vitrage_double, :vitrage_simple_double,
                                   :nouvelles_fenetres_pieces_seches, :hoogrendement_bevestiging, :vergunningsplichtig,
                                   # Nouveaux champs vitrage MVP (Mijn Verbouwpremie)
                                   :vitrage_remplacement_seul, :vitrage_depose_pose, :vitrage_supprimer_parapets,
                                   :date_publication_vitrage, :permis_notification_vitrage,
                                   :fenetres_zones_seches, :grilles_ventilation_vitrage,
                                   :systeme_ventilation_vitrage, :cpe_ventilation_vitrage,
                                   :remplacement_pour_vitrage,
                                   # Champs administratifs MVP Flandre
                                   :destination_batiment, :acheteur_protege, :proprietaire, :domicile_ici,
                                   :autre_bien_belgique, :autre_bien_etranger, :aucune_autre_propriete,
                                   :travaux_a_domicile, :verbouwloning, :pas_iban_belge,
                                   # Champs détaillés pour portes
                                   :travaux_portes, :surface_portes, :date_placement_portes, :type_portes, :marque_portes,
                                   :valeur_u_portes, :ouvertures_pieces_humides,
                                   # Champs détaillés pour chauffage
                                   :type_systeme_chauffage, :date_placement_chauffage, :marque_chauffage,
                                   :remplacement_chauffage_electrique, :raccordement_gaz,
                                   # Champs pompes à chaleur géothermique
                                   :marque_pac_geo, :type_pac_geo, :puissance_thermique_geo, :puissance_electrique_geo,
                                   :puissance_gaz_geo, :label_europeen_geo,
                                   # Champs pompes à chaleur air-eau
                                   :marque_pac_air_eau, :type_pac_air_eau, :puissance_thermique_air_eau, :puissance_electrique_air_eau,
                                   :puissance_gaz_air_eau, :label_europeen_air_eau,
                                   # Champs pompes à chaleur air-air
                                   :marque_pac_air_air, :type_pac_air_air, :puissance_thermique_air_air, :puissance_electrique_air_air,
                                   :puissance_gaz_air_air, :label_europeen_air_air,
                                   # Champs pompes à chaleur hybride
                                   :marque_pac_hybride, :type_pac_hybride, :puissance_thermique_hybride, :puissance_electrique_hybride,
                                   :puissance_gaz_hybride, :label_europeen_hybride,
                                   # Champs boiler thermodynamique
                                   :travaux_boiler, :marque_boiler, :type_boiler,
                                   :puissance_electrique_boiler, :puissance_thermique_boiler, :label_europeen_boiler,
                                   # Champs efficacité énergétique PAC
                                   :efficacite_energetique_air_air, :efficacite_energetique_hybride,
                                   # Champs détaillés pour ventilation
                                   :type_systeme_ventilation, :date_placement_ventilation, :marque_ventilation,
                                   # Champs détaillés pour travaux complémentaires
                                   :description_complementaires,
                                   # Champs pour désamiantage
                                   :localisation_desamiantage,
                                   # Champ date_raccordement_electricite
                                   :date_raccordement_electricite,
                                   # Support pour les fichiers
                                   :document_devis, :document_factures, :document_aer, :document_peb,
                                   :document_attestations, :document_photos, :document_autres,
                                   membres_famille: [:nrn, :nom, :handicap, :handicap_hidden],
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

    # Convertir membres_famille (hash indexé) en tableau si présent
    if permitted_params[:membres_famille].present?
      membres = permitted_params[:membres_famille]
      membres_array = membres.keys.sort_by(&:to_i).map do |k|
        membre = membres[k]
        {
          'nrn' => membre[:nrn].to_s,
          'nom' => membre[:nom].to_s,
          'handicap' => (membre[:handicap] == 'oui') ? 'oui' : 'non'
        }
      end
      permitted_params[:membres_famille] = membres_array
    end

    # Extraire les données de formulaire (tous les autres champs)
    # IMPORTANT: Ne pas rejeter les valeurs "0" (checkbox non cochées) ni les chaînes vides pour certains champs
    form_data_fields = permitted_params.except(*base_fields, *file_fields).reject { |k, v| v.nil? }

    Rails.logger.info "=== EXTRACT_FORM_DATA DEBUG ==="
    Rails.logger.info "Form data fields extracted: #{form_data_fields.keys}"
    Rails.logger.info "Surface toiture: #{form_data_fields[:surface_toiture] || form_data_fields['surface_toiture']}"
    Rails.logger.info "Marque toiture: #{form_data_fields[:marque_toiture] || form_data_fields['marque_toiture']}"
    Rails.logger.info "Travaux toiture: #{form_data_fields[:travaux_toiture] || form_data_fields['travaux_toiture']}"

    # CORRECTION: Fusionner avec les données existantes au lieu d'écraser
    if form_data_fields.present?
      # Pour une mise à jour (requête existante)
      request_id = params[:id]
      if request_id && Request.exists?(id: request_id)
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
      # Normaliser la date de raccordement : l'entité property stocke une année (integer),
      # mais les radio buttons Flandre attendent 'avant_2006' ou 'apres_2006'
      date_raccordement_electricite: (begin
                                        year = property.date_raccordement_electrique.to_i
                                        year > 0 ? (year < 2006 ? 'avant_2006' : 'apres_2006') : nil
                                      end),
      adresse: "#{property.numero} #{property.rue}",
      numero: property.numero,
      rue: property.rue,
      code_postal: property.code_postal,
      commune: property.commune,
      heritage_address: property.rue,
      heritage_number: property.numero,
      heritage_postal_code: property.code_postal,
      heritage_city: property.commune,

      # Type et usage selon la région
      # Normaliser les valeurs property → valeurs attendues par les radio buttons Flandre
      type_bien: (if property.region&.downcase == 'flandre'
                    case property.type_bien_flandre
                    when 'maison' then 'maison_unifamiliale'
                    when 'appartement_copro' then 'appartement'
                    when 'immeuble_appartements' then 'immeuble'
                    else property.type_bien_flandre
                    end
                  else
                    map_property_type(property)
                  end),
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
end
