class SimulationsController < ApplicationController
  # Exemptions temporaires pour les tests (à sécuriser en production)
  skip_before_action :verify_authenticity_token, only: [:update_prime_inputs, :restore_prime_inputs]
  skip_before_action :authenticate_user!, only: [:show, :update_prime_inputs, :restore_prime_inputs]

  # ✅ SÉCURITÉ: Vérifier que la simulation appartient à l'utilisateur pour les actions individuelles
  before_action :set_and_verify_simulation, only: [:show, :edit, :update, :destroy, :check_eligibility, :calculate_category, :calculate_primes, :calculate_prime, :update_prime_inputs, :restore_prime_inputs]

  def index
    # ✅ CORRECTION SÉCURITÉ: Filtrer les simulations par utilisateur connecté
    # Récupérer uniquement les simulations de l'utilisateur connecté
    user_simulations = current_user.simulations.includes(:property, :project)

    # Si property_id est fourni, filtrer par ce bien spécifique
    if params[:property_id].present?
      @property = current_user.properties.find(params[:property_id])
      @simulations = user_simulations.where(property: @property).order(created_at: :desc)
    else
      # Trier les simulations par région (Flandre → Bruxelles → Wallonie)
      @simulations = user_simulations.sort_by do |simulation|
        case simulation.region&.downcase
        when 'flandre' then 1
        when 'bruxelles' then 2
        when 'wallonie' then 3
        else 4 # Autres régions en dernier
        end
      end
    end
  end

  def show
    # @simulation est déjà définie et vérifiée par before_action

    # Charger les primes selon la région de la simulation (normaliser la casse)
    if @simulation.region.present?
      normalized_region = @simulation.region.downcase
      @primes = Prime.where(region: normalized_region).order(:ordre_affichage)
    else
      @primes = []
    end

    # Extraire les données des primes et le total depuis les paramètres
    if @simulation.parameters.present?
      params_data = safe_parse_simulation_parameters(@simulation)
      @prime_cards = params_data['prime_cards'] || {}
      @total_amount = @simulation.total_simule || 0

      # Exposer les données spécifiques Flandre si présentes
      if @simulation.region&.downcase == 'flandre'
        @peb_data = params_data['peb_data']
        @amiante_data = params_data['amiante_data']
        Rails.logger.info "🏴󐁧󐁢󐁳󐁣󐁴󐁿 Données Flandre récupérées: PEB=#{@peb_data.present?}, Amiante=#{@amiante_data.present?}"
      end
    else
      @prime_cards = {}
      @total_amount = 0
      @peb_data = nil
      @amiante_data = nil
    end

    # Vérifier l'éligibilité réelle selon les revenus actuels
    @real_eligibility = check_real_eligibility(@simulation)

    # S'assurer que total_simule est cohérent avec les paramètres
    if @simulation.total_simule.nil? || @simulation.total_simule == 0
      begin
        params_data = safe_parse_simulation_parameters(@simulation)
        if params_data.present? && params_data['total_amount'].present?
          calculated_total = params_data['total_amount'].to_f
          @simulation.update_column(:total_simule, calculated_total)
          @total_amount = calculated_total
          Rails.logger.info "🔧 Total mis à jour pour simulation #{@simulation.id}: #{calculated_total}€"
        end
      rescue => e
        Rails.logger.warn "Erreur mise à jour total simulation #{@simulation.id}: #{e.message}"
      end
    else
      # Si parameters est présent, utiliser les totaux des paramètres
      if @simulation.parameters.present?
        params_data = safe_parse_simulation_parameters(@simulation)
        calculated_total = params_data['total_general'] || params_data['total'] || 0
        if calculated_total > 0
          @simulation.update_column(:total_simule, calculated_total)
          @total_amount = calculated_total
        end
      end
    end

    # Rendre les variables disponibles dans la vue pour compatibilité
    @prime_cards_data = @prime_cards
    @simulation_total = @total_amount

    # Répondre selon le format demandé
    respond_to do |format|
      format.html # Vue normale
      format.json {
        render json: {
          total_amount: @total_amount,
          peb_data: @peb_data,
          amiante_data: @amiante_data,
          prime_cards: @prime_cards
        }
      }
    end
  end

  def new
    @simulation = Simulation.new

    # Si un project_id est passé, pré-remplir la simulation avec les données du projet
    if params[:project_id].present?
      @project = Project.find(params[:project_id])
      @simulation.property = @project.property if @project.property.present?
      # Ajouter d'autres pré-remplissages si nécessaire
    end
  end

  def create
    @simulation = current_user.simulations.build(simulation_params)

    if @simulation.save
      # Déclencher le processus de simulation en 3 étapes
      # ÉTAPE 1: Test d'éligibilité (vous pouvez implémenter la logique plus tard)
      perform_eligibility_test(@simulation)

      redirect_to @simulation, notice: 'Simulation créée avec succès. Test d\'éligibilité en cours...'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @simulation est déjà définie et vérifiée par before_action
  end

  def update
    # @simulation est déjà définie et vérifiée par before_action
    if @simulation.update(simulation_params)
      redirect_to @simulation
    else
      render :edit
    end
  end

  def destroy
    # @simulation est déjà définie et vérifiée par before_action
    simulation_title = @simulation.titre

    begin
      @simulation.destroy
      redirect_to simulations_path, notice: "La simulation '#{simulation_title}' a été supprimée avec succès."
    rescue => e
      redirect_to @simulation, alert: "Erreur lors de la suppression de la simulation : #{e.message}"
    end
  end

  # Routes AJAX pour les étapes de simulation
  def check_eligibility
    # @simulation est déjà définie et vérifiée par before_action
    begin
      perform_eligibility_test(@simulation)

      respond_to do |format|
        format.json {
          render json: {
            success: true,
            eligible: @simulation.eligible,
            message: @simulation.eligible? ? @simulation.category_description : @simulation.ineligibility_reason,
            next_step: @simulation.eligible? ? 'category' : nil
          }
        }
      end
    rescue => e
      Rails.logger.error "Erreur lors du test d'éligibilité: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      respond_to do |format|
        format.json {
          render json: {
            success: false,
            error: "Erreur lors de la vérification d'éligibilité: #{e.message}"
          }, status: :internal_server_error
        }
      end
    end
  end

  def calculate_category
    # @simulation est déjà définie et vérifiée par before_action
    perform_category_determination(@simulation)

    respond_to do |format|
      format.json {
        render json: {
          eligible: @simulation.eligible,
          category: @simulation.category,
          message: @simulation.category_description,
          next_step: @simulation.category.present? ? 'primes' : nil
        }
      }
    end
  end

  def calculate_primes
    # @simulation est déjà définie et vérifiée par before_action

    begin
      perform_primes_calculation(@simulation)

      respond_to do |format|
        format.json {
          params_data = safe_parse_simulation_parameters(@simulation)
          prime_cards = params_data['prime_cards'] || []
          render json: {
            success: true,
            eligible: @simulation.eligible,
            category: @simulation.category,
            total_primes: @simulation.total_simule,
            cards: prime_cards,
            final_result: true
          }
        }
      end
    rescue => e
      Rails.logger.error "Erreur lors du calcul des primes: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      respond_to do |format|
        format.json {
          render json: {
            success: false,
            message: "Erreur lors du calcul: #{e.message}"
          }
        }
      end
    end
  end

  def calculate_prime
    # @simulation est déjà définie et vérifiée par before_action

    begin
      # Récupérer les paramètres de la requête
      prime_slug = params[:prime_slug]
      input_value = params[:input_value]&.to_f || 0
      input_type = params[:input_type]

      return render json: { success: false, error: 'Prime slug manquant' } if prime_slug.blank?

      # Utiliser le service approprié selon la région
      calculator_service = case @simulation.region
      when 'wallonie'
        Regions::Wallonie::WalloniePostLoginCalculatorService.new(
          property: @simulation.property,
          category: @simulation.category,
          params: {}
        )
      when 'flandre'
        Regions::Flandre::FlandrePostLoginCalculatorService.new(
          property: @simulation.property,
          category: @simulation.category,
          params: {}
        )
      else
        return render json: { success: false, error: "Région #{@simulation.region} non supportée" }
      end

      # Calculer la prime individuelle
      result = calculator_service.calculate_prime(prime_slug, input_value, input_type)

      if result[:error]
        render json: { success: false, error: result[:error] }
      else
        render json: {
          success: true,
          calculated_amount: result[:calculated_amount],
          user_input_value: result[:user_input_value],
          category_data: result[:category_data]
        }
      end

    rescue => e
      Rails.logger.error "Erreur lors du calcul de prime individuelle: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      render json: {
        success: false,
        error: "Erreur lors du calcul: #{e.message}"
      }
    end
  end

  def update_prime_inputs
    # @simulation est déjà définie et vérifiée par before_action

    # to_unsafe_h: user_inputs est stock\u00e9 dans une colonne JSON, pas en mass assignment AR
    Rails.logger.info "🔍 Params bruts reçus: #{params[:user_inputs].inspect}"
    user_inputs = if params[:user_inputs].present?
      permitted_inputs = params.require(:user_inputs).to_unsafe_h
      Rails.logger.info "🔧 Après to_unsafe_h: #{permitted_inputs.inspect}"
      permitted_inputs
    else
      {}
    end

    # Récupérer le total calculé côté client si disponible
    calculated_total = params[:calculated_total]&.to_f

    Rails.logger.info "🔄 Updating simulation #{@simulation.id} with #{user_inputs.keys.length} inputs"
    Rails.logger.info "📊 Total côté client: #{calculated_total}€" if calculated_total

    # Si pas de données ET aucune donnée existante, retourner succès (pour l'auto-save vide initial)
    if user_inputs.empty? && @simulation.total_simule.present? && @simulation.total_simule > 0
      Rails.logger.info "📝 Auto-save vide ignoré pour simulation #{@simulation.id} avec données existantes"
      render json: {
        success: true,
        message: "Aucune nouvelle donnée à sauvegarder",
        total_amount: @simulation.total_simule || 0
      }
      return
    end

    begin
      # Si on a un total calculé côté client (pour Wallonie/Flandre/Bruxelles), l'utiliser directement
      if %w[wallonie flandre bruxelles].include?(@simulation.region&.downcase)
        Rails.logger.info "🚀 Utilisation des nouvelles méthodes calculate_all_primes"

        if @simulation.region&.downcase == 'bruxelles'
          # Pour Bruxelles, utiliser le nouveau système
          Rails.logger.info "🏛️ Utilisation des nouvelles méthodes calculate_all_primes pour Bruxelles"
          Rails.logger.info "🔧 Instanciation du nouveau service BruxellesPostLoginCalculatorService"
          calculator_service = Regions::Bruxelles::BruxellesPostLoginCalculatorService.new(
            {
              property_id: @simulation.property_id,
              project_id: @simulation.project_id,
              simulation_type: 'particulier'
            },
            user: current_user
          )

          # Appeler la méthode calculate_all_primes du nouveau service
          Rails.logger.info "🔧 Appel de calculate_all_primes avec: #{user_inputs.inspect}"
          result = calculator_service.calculate_all_primes(user_inputs)
          Rails.logger.info "✅ Total calculé avec nouvelles méthodes Bruxelles: #{result[:total_general]}€"
          Rails.logger.info "🔧 Prime results reçus: #{result[:prime_results].inspect}"

          # Construire la structure updated_cards attendue par le frontend
          updated_cards = build_updated_cards_from_prime_results(result[:prime_results])
          Rails.logger.info "🔧 Updated cards construites: #{updated_cards.inspect}"

          # Utiliser le total calculé par le backend et mettre à jour la simulation
          @simulation.update!(total_simule: result[:total_general])

          render json: {
            success: true,
            total_amount: result[:total_general],
            updated_cards: updated_cards,
            message: "Total mis à jour avec nouvelles méthodes Bruxelles"
          }
          return
        elsif @simulation.region&.downcase == 'wallonie'
          # Pour Wallonie, utiliser le nouveau système comme Bruxelles
          Rails.logger.info "🚀 Utilisation des nouvelles méthodes calculate_all_primes pour Wallonie (force debug)"
          Rails.logger.info "🔧 Instanciation du nouveau service WalloniePostLoginCalculatorService"
          calculator_service = Regions::Wallonie::WalloniePostLoginCalculatorService.new(
            {
              property_id: @simulation.property_id,
              project_id: @simulation.project_id,
              simulation_type: 'particulier'
            },
            user: current_user
          )

          # Appeler la méthode calculate_all_primes du nouveau service
          Rails.logger.info "🔧 Appel de calculate_all_primes avec: #{user_inputs.inspect}"
          result = calculator_service.calculate_all_primes(user_inputs)
          Rails.logger.info "✅ Total calculé avec nouvelles méthodes Wallonie: #{result[:total_general]}€"
          Rails.logger.info "🔧 Prime results reçus: #{result[:prime_results].inspect}"

          # Construire la structure updated_cards attendue par le frontend
          updated_cards = build_updated_cards_from_prime_results(result[:prime_results])
          Rails.logger.info "🔧 Updated cards construites: #{updated_cards.inspect}"

          # Utiliser le total calculé par le backend et mettre à jour la simulation
          @simulation.update!(total_simule: result[:total_general])

          # Sauvegarder les données Wallonie dans les paramètres de la simulation
          save_wallonie_specific_data(user_inputs, result[:prime_results])

          render json: {
            success: true,
            total_amount: result[:total_general],
            updated_cards: updated_cards, # ✅ Structure des primes individuelles
            message: "Total mis à jour avec nouvelles méthodes Wallonie"
          }
        elsif @simulation.region&.downcase == 'flandre'
          # Pour Flandre, utiliser le nouveau système avec gestion PEB/Amiante
          Rails.logger.info "🏴󐁧󐁢󐁳󐁣󐁴󐁿 Utilisation des nouvelles méthodes calculate_all_primes pour Flandre"
          Rails.logger.info "🔧 Instanciation du nouveau service FlandrePostLoginCalculatorService"
          calculator_service = Regions::Flandre::FlandrePostLoginCalculatorService.new(
            {
              property_id: @simulation.property_id,
              project_id: @simulation.project_id,
              simulation_type: 'particulier',
              category: @simulation.category
            },
            user: current_user
          )

          # Appeler la méthode calculate_all_primes du nouveau service
          # Restructurer les données pour le service Flandre
          structured_inputs = restructure_flandre_inputs(user_inputs)
          Rails.logger.info "🔧 Données restructurées pour Flandre: #{structured_inputs.inspect}"

          Rails.logger.info "🔧 Appel de calculate_all_primes Flandre avec: #{structured_inputs.inspect}"
          result = calculator_service.calculate_all_primes(structured_inputs)
          Rails.logger.info "✅ Total calculé avec nouvelles méthodes Flandre: #{result[:total_general]}€"
          Rails.logger.info "🔧 Prime results reçus: #{result[:prime_results].inspect}"

          # Construire la structure updated_cards attendue par le frontend
          updated_cards = build_updated_cards_from_prime_results(result[:prime_results])
          Rails.logger.info "🔧 Updated cards construites: #{updated_cards.inspect}"

          # Utiliser le total calculé côté client s'il est disponible (inclut primes + PEB + amiante)
          # Sinon utiliser le total des primes uniquement
          final_total = calculated_total && calculated_total > 0 ? calculated_total : result[:total_general]
          Rails.logger.info "💰 Total final utilisé: #{final_total}€ (source: #{calculated_total && calculated_total > 0 ? 'frontend complet' : 'backend primes uniquement'})"

          # Mettre à jour la simulation avec le total final
          @simulation.update!(total_simule: final_total)

          # Sauvegarder les données dans les paramètres de la simulation
          save_flandre_specific_data(user_inputs, result[:prime_results])

          render json: {
            success: true,
            total_amount: final_total,
            updated_cards: updated_cards,
            message: "Total mis à jour avec nouvelles méthodes Flandre (PEB/Amiante inclus)"
          }
        else
          # Pour autres régions, utiliser l'ancien système pour l'instant
          updater = SimulationPrimesUpdater.new(@simulation)
          result = updater.update_user_inputs(user_inputs)

          if result[:success]
            @simulation.update!(total_simule: calculated_total)

            render json: {
              success: true,
              total_amount: calculated_total,
              updated_cards: result[:updated_cards],
              message: "Total mis à jour avec ancien système Wallonie"
            }
          else
            # Fallback si le service backend échoue
            render json: {
              success: true,
              total_amount: calculated_total,
              message: "Total mis à jour côté client (détails backend indisponibles)"
            }
          end
        end
        return
      end

      # Sinon utiliser l'ancienne méthode avec le service
      # Rails.logger.info "🔧 Creating SimulationPrimesUpdater for simulation #{@simulation.id}"
      updater = SimulationPrimesUpdater.new(@simulation)

      # Rails.logger.info "🔧 Calling update_user_inputs with: #{user_inputs.inspect}"
      result = updater.update_user_inputs(user_inputs)

      # Rails.logger.info "🔧 Service returned: #{result.inspect}"

      if result[:success]
        # Rails.logger.info "✅ Simulation #{@simulation.id} updated successfully: #{result[:total_amount]}€"

        render json: result
      else
        Rails.logger.error "❌ Failed to update simulation #{@simulation.id}: #{result[:error]}"
        render json: { success: false, error: result[:error] }, status: :unprocessable_entity
      end

    rescue => e
      Rails.logger.error "❌ Exception in update_prime_inputs: #{e.message}"
      Rails.logger.error "❌ Exception class: #{e.class}"
      Rails.logger.error "❌ Exception backtrace: #{e.backtrace.join("\n")}"
      render json: { success: false, error: "Erreur lors de la sauvegarde: #{e.message}" }, status: :internal_server_error
    end
  end

  def restore_prime_inputs
    # @simulation est déjà définie et vérifiée par before_action

    # Rails.logger.info "🔄 Restoring prime inputs for simulation #{@simulation.id}"

    begin
      # Parser les paramètres de la simulation
      params_data = safe_parse_simulation_parameters(@simulation)

      if params_data.empty?
        Rails.logger.warn "⚠️ No parameters found for simulation #{@simulation.id}"
        render json: { success: true, user_inputs: {}, message: "Aucune donnée à restaurer" }
        return
      end

      # Extraire les inputs utilisateur depuis la structure prime_cards
      user_inputs = {}

      if params_data["prime_cards"].present?
        params_data["prime_cards"].each do |category_key, category_data|
          next unless category_data["primes"].present?

          category_data["primes"].each do |prime|
            if prime["user_input_value"].present?
              user_inputs[prime["slug"]] = prime["user_input_value"]
            end
          end
        end
      end

      # Gestion spéciale pour les données Flandre (PEB et Amiante)
      if @simulation.region&.downcase == 'flandre'
        if params_data["peb_data"].present?
          user_inputs["peb"] = params_data["peb_data"]
          Rails.logger.info "🔄 Données PEB restaurées: #{params_data['peb_data'].inspect}"
        end

        if params_data["amiante_data"].present?
          user_inputs["amiante"] = params_data["amiante_data"]
          Rails.logger.info "🔄 Données Amiante restaurées: #{params_data['amiante_data'].inspect}"
        end

        # Fallback: chercher les données directes pour les primes Flandre (nouvelles méthodes)
        flandre_prime_keys = %w[isolation_toiture isolation_murs isolation_sol ramen_deuren warmtepomp warmtepompboiler voorbereiding_isolatie voorbereiding_sanitair_elec renovation_toiture renovation_murs renovation_sol]
        flandre_prime_keys.each do |key|
          if params_data[key].present? && params_data[key] != 0 && params_data[key] != "0"
            user_inputs[key] = params_data[key]
            Rails.logger.info "🔄 Prime Flandre restaurée: #{key} = #{params_data[key]}"
          end
        end
      end

      # Gestion pour Wallonie - chercher toutes les clés qui commencent par wallonie_
      if @simulation.region&.downcase == 'wallonie'
        Rails.logger.info "🔍 Recherche des primes Wallonie dans params_data..."
        params_data.each do |key, value|
          if key.to_s.start_with?('wallonie_') && value.present? && value != 0 && value != "0"
            user_inputs[key] = value
            Rails.logger.info "🔄 Prime Wallonie restaurée: #{key} = #{value}"
          end
        end
        Rails.logger.info "✅ #{user_inputs.keys.length} primes Wallonie restaurées"
      end

      # Recalculer les montants pour updated_cards si nécessaire
      updated_cards = nil
      if params_data["prime_cards"].present?
        # Utiliser la structure prime_cards existante
        updated_cards = params_data["prime_cards"]
      elsif @simulation.region&.downcase == 'wallonie' && user_inputs.any?
        # Recalculer pour Wallonie si on a des inputs
        Rails.logger.info "🔄 Recalcul des montants Wallonie pour restauration..."
        begin
          calculator_service = Regions::Wallonie::WalloniePostLoginCalculatorService.new(
            {
              property_id: @simulation.property_id,
              project_id: @simulation.project_id,
            },
            user: @simulation.user
          )
          calculator_service.instance_variable_set(:@category, @simulation.category)
          result = calculator_service.calculate_all_primes(user_inputs)
          updated_cards = build_updated_cards_from_prime_results(result[:prime_results])
          Rails.logger.info "✅ Montants Wallonie recalculés pour restauration"
        rescue => calc_error
          Rails.logger.error "⚠️ Erreur recalcul Wallonie: #{calc_error.message}"
        end
      end

      # Rails.logger.info "✅ Restored #{user_inputs.keys.length} user inputs for simulation #{@simulation.id}"
      render json: {
        success: true,
        user_inputs: user_inputs,
        total_amount: @simulation.total_simule,
        category: @simulation.category,
        updated_cards: updated_cards
      }

    rescue => e
      Rails.logger.error "❌ Exception in restore_prime_inputs: #{e.message}"
      Rails.logger.error "❌ Exception backtrace: #{e.backtrace.join("\n")}"
      render json: { success: false, error: "Erreur lors de la restauration: #{e.message}" }, status: :internal_server_error
    end
  end

  private

  # Transforme le résultat du nouveau service en structure updated_cards attendue par le frontend
  def build_updated_cards_from_prime_results(prime_results)
    updated_cards = {}

    Rails.logger.info "🔧 Début construction updated_cards avec: #{prime_results.inspect}"

    # Grouper les primes par catégorie comme SimulationPrimesUpdater
    categorized_primes = {}

    prime_results.each do |slug, prime_data|
      # prime_data contient { amount: X, prime_id: Y, titre: Z, unite: W }
      # OU pour Flandre: { calculated_amount: X, user_input_value: Y, category_data: Z }
      amount = prime_data[:amount] || prime_data[:calculated_amount] || prime_data['amount'] || prime_data['calculated_amount'] || 0

      Rails.logger.info "🔧 Prime #{slug}: #{amount}€ (data: #{prime_data})"

      # Déterminer la catégorie basée sur le slug
      category = determine_category_from_slug(slug)

      categorized_primes[category] ||= {
        total: 0,
        primes: []
      }

      # Ajouter la prime à la catégorie
      categorized_primes[category][:primes] << {
        slug: slug,
        titre: prime_data[:titre] || prime_data['titre'] || slug.humanize,
        calculated_amount: amount,
        user_input_value: 1 # Valeur par défaut pour les primes activées
      }

      # Ajouter au total de la catégorie
      categorized_primes[category][:total] += amount

      # CRUCIAL: Ajouter aussi le slug directement pour les controllers individuels
      updated_cards[slug] = amount
    end

    # Ajouter les catégories organisées
    categorized_primes.each do |category, data|
      updated_cards[category] = data
    end

    Rails.logger.info "🔧 Structure updated_cards finale construite: #{updated_cards}"
    updated_cards
  end

  # Détermine la catégorie d'une prime basée sur son slug
  def determine_category_from_slug(slug)
    case slug
    when /audit/
      'audit'
    when /certificat/
      'certificat'
    when /isolation/
      'isolation'
    when /chauffage/
      'chauffage'
    when /ventilation/
      'ventilation'
    when /solaire/
      'solaire'
    else
      'autres'
    end
  end

  # Helper pour parser les paramètres de simulation de manière sécurisée
  def safe_parse_simulation_parameters(simulation)
    return {} unless simulation.parameters.present? && simulation.parameters.strip != ""

    begin
      JSON.parse(simulation.parameters)
    rescue JSON::ParserError => e
      Rails.logger.warn "Failed to parse simulation parameters for simulation #{simulation.id}: #{e.message}"
      {}
    end
  end

  # Méthode optimisée pour recalculer avec les saisies utilisateur
  def recalculate_with_user_inputs(user_inputs)
    return {} unless @simulation.category.present?

    # Rails.logger.info "Recalculating with #{user_inputs.keys.length} user inputs for category #{@simulation.category}"

    begin
      # Choisir le service de calcul selon la région
      region = @simulation.region&.downcase

      if region == 'wallonie'
        calculator_service = Regions::Wallonie::WalloniePostLoginCalculatorService.new(
          {
            property_id: @simulation.property_id,
            project_id: @simulation.project_id,
            user_inputs: user_inputs  # Passer les saisies au service
          },
          user: current_user
        )
      elsif region == 'flandre'
        calculator_service = Regions::Flandre::FlandrePostLoginCalculatorService.new(
          {
            property_id: @simulation.property_id,
            project_id: @simulation.project_id,
            user_inputs: user_inputs  # Passer les saisies au service
          },
          user: current_user
        )
      else
        raise "Région '#{region}' non supportée"
      end

      category_result = {
        category: @simulation.category,
        eligible: true
      }

      # Recalculer avec les nouvelles données de manière optimisée
      start_time = Time.current
      cards_data = calculator_service.generate_prime_cards(category_result)
      calculation_time = Time.current - start_time

      # Rails.logger.info "Calculation completed in #{calculation_time.round(3)}s for #{cards_data[:prime_cards]&.keys&.length || 0} categories"

      {
        'prime_cards' => cards_data[:prime_cards],
        'total_general' => cards_data[:total_general],
        'category_used' => cards_data[:category_used],
        'calculation_timestamp' => Time.current,
        'calculation_duration' => calculation_time.round(3)
      }

    rescue StandardError => e
      Rails.logger.error "Error in recalculate_with_user_inputs: #{e.message}"
      raise e
    end
  end

  private

  # ✅ SÉCURITÉ: Méthode pour charger et vérifier que la simulation appartient à l'utilisateur
  def set_and_verify_simulation
    @simulation = Simulation.find(params[:id])

    # Vérifier que la simulation appartient à l'utilisateur connecté (sauf si pas d'authentification requise)
    if user_signed_in? && @simulation.user != current_user
      redirect_to root_path, alert: "Accès non autorisé à cette simulation"
      return
    elsif !user_signed_in?
      # Pour les actions sans authentification (show, update_prime_inputs, restore_prime_inputs)
      # On autorise l'accès mais on limite les fonctionnalités
      Rails.logger.info "🔓 Accès sans authentification à la simulation #{@simulation.id}"
    end
  end

  def simulation_params
    params.require(:simulation).permit(:titre, :region, :parameters, :source, :property_id, :project_id, :user_id,
                                       :eligible, :category, :category_description, :ineligibility_reason)
  end

  # ÉTAPE 1: Test d'éligibilité
  def perform_eligibility_test(simulation)
    # Rails.logger.info "=== PERFORM_ELIGIBILITY_TEST ==="
    # Rails.logger.info "Simulation ID: #{simulation.id}, region: '#{simulation.region}'"
    # Rails.logger.info "Property present: #{simulation.property.present?}"

    region = simulation.region&.downcase

    unless ['wallonie', 'flandre', 'bruxelles'].include?(region)
      # Rails.logger.info "SKIPPED: Region '#{simulation.region}' is not supported yet"
      return
    end

    unless simulation.property.present?
      # Rails.logger.info "SKIPPED: No property associated"
      return
    end

    # Rails.logger.info "Proceeding with eligibility test for region: #{region}"
    # Rails.logger.info "📋 Simulation property_id: #{simulation.property_id}"
    # Rails.logger.info "📋 Simulation project_id: #{simulation.project_id}"

    # Choisir le service d'éligibilité selon la région
    if region == 'wallonie'
      eligibility_service = Regions::Wallonie::WallonieEligibilityService.new(
        {
          property_id: simulation.property_id,
          project_id: simulation.project_id
        },
        user: current_user
      )
    elsif region == 'flandre'
      eligibility_service = Regions::Flandre::FlandreEligibilityService.new(
        {
          property_id: simulation.property_id,
          project_id: simulation.project_id
        },
        user: current_user
      )
    elsif region == 'bruxelles'
      eligibility_service = Regions::Bruxelles::BruxellesEligibilityService.new(
        {
          property_id: simulation.property_id,
          project_id: simulation.project_id
        },
        user: current_user
      )
    end

    result = eligibility_service.check_eligibility

    if result[:eligible]
      simulation.update(
        eligible: true,
        category_description: result[:message]
      )
      # Déclencher l'étape 2 automatiquement pour Wallonie, Flandre et Bruxelles
      perform_category_determination(simulation) if ['wallonie', 'flandre', 'bruxelles'].include?(region)
    else
      simulation.update(
        eligible: false,
        ineligibility_reason: result[:message]
      )
    end
  end

  # ÉTAPE 2: Détermination de la catégorie
  def perform_category_determination(simulation)
    region = simulation.region&.downcase
    return unless simulation.eligible? && ['wallonie', 'flandre'].include?(region)

    # Choisir le service de catégorie selon la région
    if region == 'wallonie'
      category_service = Regions::Wallonie::WallonieCategoryService.new(
        {
          property_id: simulation.property_id,
          project_id: simulation.project_id
        },
        user: current_user
      )
    elsif region == 'flandre'
      category_service = Regions::Flandre::FlandreCategoryService.new(
        {
          property_id: simulation.property_id,
          project_id: simulation.project_id
        },
        user: current_user
      )
    elsif region == 'bruxelles'
      category_service = Regions::Bruxelles::BruxellesCategoryService.new(
        {
          property_id: simulation.property_id,
          project_id: simulation.project_id
        },
        user: current_user
      )
    end

    result = category_service.determine_category

    if result[:error]
      # Gestion des erreurs spécifiques
      simulation.update(
        eligible: false,
        ineligibility_reason: result[:error]
      )
    else
      # Succès - mise à jour avec la catégorie
      # Préparer les paramètres existants (gérer les chaînes vides)
      existing_params = safe_parse_simulation_parameters(simulation)
      existing_params.merge!({
        'exact_income' => result[:exact_income],
        'thresholds_used' => result[:thresholds_used]
      })

      simulation.update(
        category: result[:category],
        category_description: result[:details],
        parameters: existing_params.to_json
      )
      # Déclencher l'étape 3 automatiquement
      perform_primes_calculation(simulation)
    end
  end

  # ÉTAPE 3: Calcul des primes
  def perform_primes_calculation(simulation)
    region = simulation.region&.downcase
    return unless simulation.eligible? && simulation.category.present?

    # Choisir le service de calcul selon la région
    if region == 'wallonie'
      calculator_service = Regions::Wallonie::WalloniePostLoginCalculatorService.new(
        {
          property_id: simulation.property_id,
          project_id: simulation.project_id
        },
        user: current_user
      )
    elsif region == 'flandre'
      calculator_service = Regions::Flandre::FlandrePostLoginCalculatorService.new(
        {
          property_id: simulation.property_id,
          project_id: simulation.project_id
        },
        user: current_user
      )
    else
      Rails.logger.error "❌ Région non supportée pour calcul de primes: #{region}"
      return
    end

    # Préparer les données de catégorie pour le calculateur
    category_result = {
      category: simulation.category,
      eligible: true
    }

    # Générer les cartes de primes structurées
    cards_data = calculator_service.generate_prime_cards(category_result)

    # Mettre à jour la simulation avec les données des cartes
    if region == 'wallonie'
      existing_params = safe_parse_simulation_parameters(simulation)

      # Préserver toutes les saisies utilisateur (clés wallonie_*) et fusionner avec les nouvelles données calculées
      merged_params = existing_params.merge({
        'prime_cards'           => cards_data[:cards],
        'total_general'         => cards_data[:total],
        'category_used'         => cards_data[:category_used],
        'calculation_timestamp' => Time.current
      })

      simulation.update(
        total_simule: cards_data[:total],
        parameters: merged_params.to_json
      )
    elsif region == 'flandre'
      existing_params = safe_parse_simulation_parameters(simulation)

      # Convertir les nouvelles cartes (clés symbol) en string
      new_prime_cards = (cards_data[:prime_cards] || {}).transform_keys(&:to_s)

      # Restaurer les user_input_value depuis l'ancienne structure prime_cards
      if existing_params['prime_cards'].present?
        new_prime_cards.each do |group_key, group_data|
          old_group = existing_params['prime_cards'][group_key]
          next unless old_group && old_group['primes']

          primes_list = group_data.is_a?(Hash) ? (group_data[:primes] || group_data['primes'] || []) : []
          primes_list.each do |new_prime|
            slug = (new_prime[:slug] || new_prime['slug']).to_s
            old_prime = old_group['primes'].find { |p| (p['slug'] || p[:slug]).to_s == slug }
            next unless old_prime && old_prime['user_input_value'].present?
            if new_prime.is_a?(Hash)
              new_prime.store(:user_input_value, old_prime['user_input_value'])
            end
          end
        end
      end

      # Partir des params existants (préserve tous les inputs plats + PEB + amiante)
      # et mettre à jour uniquement les données calculées fraîches
      merged_params = existing_params.merge({
        'prime_cards'           => new_prime_cards,
        'total_general'         => cards_data[:total_general],
        'category_used'         => cards_data[:category_used],
        'calculation_timestamp' => cards_data[:calculation_timestamp]
      })

      simulation.update(
        total_simule: cards_data[:total_general],
        parameters: merged_params.to_json
      )
    end
  end

  # Calcule le total à partir des updated_cards
  def calculate_total_from_updated_cards(updated_cards)
    return 0 if updated_cards.blank?

    total = 0
    updated_cards.each do |key, value|
      if value.is_a?(Hash) && value[:total]
        # Catégorie avec total
        total += value[:total].to_f
      elsif value.is_a?(Numeric)
        # Prime individuelle
        total += value.to_f
      end
    end

    total
  end

  # Nouvelle méthode pour sauvegarder les données spécifiques à la Flandre
  def save_flandre_specific_data(user_inputs, prime_results = {})
    Rails.logger.info "💾 Sauvegarde des données spécifiques Flandre: #{user_inputs.inspect}"
    Rails.logger.info "💾 Résultats calculés: #{prime_results.inspect}"

    # Ne pas sauvegarder si user_inputs est complètement vide
    if user_inputs.empty?
      Rails.logger.info "⚠️ Aucune donnée à sauvegarder (user_inputs vide)"
      return
    end

    # Récupérer les paramètres existants ou initialiser
    existing_params = @simulation.parameters.present? ? JSON.parse(@simulation.parameters) : {}

    # Sauvegarder les données PEB si présentes
    if user_inputs['peb'].present?
      existing_params['peb_data'] = user_inputs['peb']
      Rails.logger.info "💾 Données PEB sauvegardées: #{user_inputs['peb'].inspect}"
    end

    # Sauvegarder les données Amiante si présentes
    if user_inputs['amiante'].present?
      existing_params['amiante_data'] = user_inputs['amiante']
      Rails.logger.info "💾 Données Amiante sauvegardées: #{user_inputs['amiante'].inspect}"
    end

    # Convertir les primes au format attendu par restore_prime_inputs
    if user_inputs['primes'].present?
      existing_params['prime_cards'] ||= {}

      user_inputs['primes'].each do |slug, prime_data|
        next unless prime_data['value'].present?

        # Déterminer la catégorie pour cette prime
        category = determine_category_from_slug(slug)

        # Initialiser la structure de catégorie si nécessaire
        existing_params['prime_cards'][category] ||= {
          'total' => 0,
          'primes' => []
        }

        # Ajouter ou mettre à jour la prime dans cette catégorie
        existing_prime = existing_params['prime_cards'][category]['primes'].find { |p| p['slug'] == slug }
        if existing_prime
          existing_prime['user_input_value'] = prime_data['value']
        else
          existing_params['prime_cards'][category]['primes'] << {
            'slug' => slug,
            'user_input_value' => prime_data['value']
          }
        end
      end

      Rails.logger.info "💾 Données primes sauvegardées dans le bon format"
    end

    # Sauvegarder aussi les données brutes pour la restructuration (fallback)
    user_inputs.each do |key, value|
      if key != 'peb' && key != 'amiante' && key != 'primes' && value.present?
        existing_params[key] = value
      end
    end

    # Sauvegarder aussi les montants calculés pour chaque prime
    if prime_results.present?
      calculated_amounts = {}
      prime_results.each do |slug, data|
        amount = data[:amount] || data[:calculated_amount] || data['amount'] || data['calculated_amount'] || 0
        calculated_amounts[slug.to_s] = amount
        Rails.logger.info "💾 Montant calculé sauvegardé: #{slug} = #{amount}€"
      end
      existing_params['calculated_amounts'] = calculated_amounts
    end

    # Horodatage de la dernière mise à jour
    existing_params['last_updated'] = Time.current.iso8601

    # Sauvegarder dans la base de données
    @simulation.update!(parameters: existing_params.to_json)

    Rails.logger.info "✅ Données Flandre sauvegardées avec succès"
  rescue => e
    Rails.logger.error "❌ Erreur lors de la sauvegarde Flandre: #{e.message}"
  end

  def save_wallonie_specific_data(user_inputs, prime_results = {})
    Rails.logger.info "💾 Sauvegarde des données spécifiques Wallonie: #{user_inputs.inspect}"
    Rails.logger.info "💾 Résultats calculés: #{prime_results.inspect}"

    # Ne pas sauvegarder si toutes les valeurs sont nulles/vides
    non_zero_values = user_inputs.select { |k, v| v.present? && v != 0 && v != "0" }
    if non_zero_values.empty?
      Rails.logger.info "⚠️ Aucune donnée significative à sauvegarder pour Wallonie"
      return
    end

    # Récupérer les paramètres existants ou initialiser
    existing_params = @simulation.parameters.present? ? JSON.parse(@simulation.parameters) : {}

    # Sauvegarder toutes les données Wallonie directement (clés qui commencent par wallonie_)
    user_inputs.each do |key, value|
      if key.to_s.start_with?('wallonie_') && value.present?
        existing_params[key.to_s] = value
        Rails.logger.info "💾 Donnée Wallonie sauvegardée: #{key} = #{value}"
      end
    end

    # Sauvegarder aussi les montants calculés pour chaque prime
    if prime_results.present?
      calculated_amounts = {}
      prime_results.each do |slug, data|
        amount = data[:amount] || data['amount'] || 0
        calculated_amounts[slug.to_s] = amount
        Rails.logger.info "💾 Montant calculé sauvegardé: #{slug} = #{amount}€"
      end
      existing_params['calculated_amounts'] = calculated_amounts
    end

    # Horodatage de la dernière mise à jour
    existing_params['last_updated'] = Time.current.iso8601

    # Sauvegarder dans la base de données
    @simulation.update!(parameters: existing_params.to_json)

    Rails.logger.info "✅ #{non_zero_values.keys.length} données Wallonie sauvegardées avec succès"
  rescue => e
    Rails.logger.error "❌ Erreur lors de la sauvegarde Wallonie: #{e.message}"
  end

  # Restructurer les données plates en structure attendue par FlandrePostLoginCalculatorService
  def restructure_flandre_inputs(flat_inputs)
    Rails.logger.info "🔄 Restructuration des données Flandre: #{flat_inputs.inspect}"

    structured = {
      'primes' => {}
    }

    # Liste des slugs normaux de primes (ni PEB ni Amiante)
    prime_slugs = %w[
      isolation_toiture isolation_murs isolation_sol
      ramen_deuren warmtepomp warmtepompboiler voorbereiding_isolatie
      voorbereiding_sanitair_elec renovation_toiture renovation_murs renovation_sol
    ]

    # Extraire le type de pompe s'il est présent (envoyé séparément)
    warmtepomp_type = flat_inputs['warmtepomp_type'].presence

    # Traiter chaque input
    flat_inputs.each do |key, value|
      if prime_slugs.include?(key.to_s)
        # C'est une prime normale
        if value.present? && value.to_f > 0
          type = key.to_s == 'warmtepomp' ? warmtepomp_type : nil
          structured['primes'][key] = {
            'value' => value.to_f,
            'type'  => type
          }
        elsif key.to_s == 'warmtepomp' && warmtepomp_type.present?
          # Pompe à chaleur : le montant est un forfait, pas besoin de valeur de facture
          structured['primes'][key] = {
            'value' => 0,
            'type'  => warmtepomp_type
          }
        end
      elsif key.to_s.start_with?('peb_')
        structured['peb'] ||= {}
        structured['peb'][key.to_s.sub('peb_', '')] = value
      elsif key.to_s.start_with?('amiante_')
        structured['amiante'] ||= {}
        structured['amiante'][key.to_s.sub('amiante_', '')] = value
      end
    end

    # Si warmtepomp_type présent mais pas encore dans primes
    if warmtepomp_type.present? && !structured['primes']['warmtepomp']
      structured['primes']['warmtepomp'] = { 'value' => 0, 'type' => warmtepomp_type }
    end

    # Supprimer les clés vides
    structured.delete('primes') if structured['primes'].empty?
    structured.delete('peb') if structured['peb']&.empty?
    structured.delete('amiante') if structured['amiante']&.empty?

    Rails.logger.info "✅ Données restructurées: #{structured.inspect}"
    structured
  end

  # Calcul du montant PEB à partir des données
  def calculate_peb_amount_from_data(peb_data)
    return 0 unless peb_data.present?

    label_initial = peb_data['label_initial']
    type_logement = peb_data['type_logement']
    ventilation    = peb_data['ventilation']
    label_final    = peb_data['label_final']
    categorie      = peb_data['categorie'].to_s.presence || '4'

    return 0 unless label_initial.present? && label_final.present? && type_logement.present? && ventilation.present?

    # Vérifier que le label final est strictement meilleur que le label initial
    label_order = { 'A' => 1, 'B' => 2, 'C' => 3, 'D' => 4, 'E' => 5, 'F' => 6 }
    return 0 unless (label_order[label_final] || 99) < (label_order[label_initial] || 99)

    # Matrice PEB Flandre - identique au seed db/seeds/flandre/peb.rb et au peb_controller.js
    peb_matrix = {
      '4' => {
        'maison'      => { 'A' => { 'avec_ventilation' => 7000, 'sans_ventilation' => 6000 },
                           'B' => { 'avec_ventilation' => 5250, 'sans_ventilation' => 4500 },
                           'C' => { 'avec_ventilation' => 3500, 'sans_ventilation' => 3000 } },
        'appartement' => { 'A' => { 'avec_ventilation' => 5250, 'sans_ventilation' => 4500 },
                           'B' => { 'avec_ventilation' => 3500, 'sans_ventilation' => 3000 } }
      },
      '3' => {
        'maison'      => { 'A' => { 'avec_ventilation' => 6000, 'sans_ventilation' => 5000 },
                           'B' => { 'avec_ventilation' => 4500, 'sans_ventilation' => 3750 },
                           'C' => { 'avec_ventilation' => 3000, 'sans_ventilation' => 2500 } },
        'appartement' => { 'A' => { 'avec_ventilation' => 4500, 'sans_ventilation' => 3750 },
                           'B' => { 'avec_ventilation' => 3000, 'sans_ventilation' => 2500 } }
      },
      '2' => {
        'maison'      => { 'A' => { 'avec_ventilation' => 5000, 'sans_ventilation' => 4000 },
                           'B' => { 'avec_ventilation' => 3750, 'sans_ventilation' => 3000 },
                           'C' => { 'avec_ventilation' => 2500, 'sans_ventilation' => 2000 } },
        'appartement' => { 'A' => { 'avec_ventilation' => 3750, 'sans_ventilation' => 3000 },
                           'B' => { 'avec_ventilation' => 2500, 'sans_ventilation' => 2000 } }
      },
      '1' => {
        'maison'      => { 'A' => { 'avec_ventilation' => 4000, 'sans_ventilation' => 3000 },
                           'B' => { 'avec_ventilation' => 3000, 'sans_ventilation' => 2000 },
                           'C' => { 'avec_ventilation' => 2000, 'sans_ventilation' => 1000 } },
        'appartement' => { 'A' => { 'avec_ventilation' => 3000, 'sans_ventilation' => 2250 },
                           'B' => { 'avec_ventilation' => 2000, 'sans_ventilation' => 1500 } }
      }
    }

    peb_matrix.dig(categorie, type_logement, label_final, ventilation).to_i
  end

  # Calcul du montant amiante à partir des données
  def calculate_amiante_amount_from_data(amiante_data)
    return 0 unless amiante_data.present?

    surface_toiture = amiante_data['surface_toiture'].to_f
    surface_murs = amiante_data['surface_murs'].to_f

    montant_total = 0

    # Logique de calcul amiante Flandre (même que côté frontend)
    # 8€/m² pour la toiture
    # 4€/m² pour les murs si pas de toiture
    # 12€/m² pour les murs si toiture incluse
    if surface_toiture > 0
      montant_total += surface_toiture * 8 # 8€/m² toiture

      if surface_murs > 0
        montant_total += surface_murs * 12 # 12€/m² murs si toiture incluse
      end
    elsif surface_murs > 0
      montant_total += surface_murs * 4 # 4€/m² murs uniquement
    end

    montant_total
  end

  # Helper pour vérifier l'éligibilité réelle selon les revenus
  def check_real_eligibility(simulation)
    return { eligible: false, reason: "Simulation non trouvée" } unless simulation
    return { eligible: false, reason: "Utilisateur non trouvé" } unless simulation.property&.user

    user = simulation.property.user
    region = simulation.region&.downcase

    case region
    when 'wallonie'
      check_wallonie_real_eligibility(user)
    when 'flandre'
      check_flandre_real_eligibility(user)
    when 'bruxelles'
      check_bruxelles_real_eligibility(user)
    else
      { eligible: false, reason: "Région non supportée" }
    end
  end

  private

  def check_wallonie_real_eligibility(user)
    return { eligible: false, reason: "Revenus non renseignés" } unless user.revenu_demandeur

    # Calcul du revenu total du ménage
    total_income = user.revenu_demandeur
    if user.situation_familiale.in?(%w[marie cohabitant couple]) && user.revenu_conjoint
      total_income += user.revenu_conjoint
    end

    # Déductions (5000€ par enfant)
    deductions = (user.nombre_enfants || 0) * 5000
    adjusted_income = [total_income - deductions, 0].max

    # Seuil Wallonie
    threshold = 114_400

    if adjusted_income > threshold
      {
        eligible: false,
        reason: "Revenus trop élevés (#{adjusted_income.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}€ > #{threshold.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}€)"
      }
    else
      { eligible: true }
    end
  end

  def check_flandre_real_eligibility(user)
    return { eligible: false, reason: "Revenus non renseignés" } unless user.revenu_demandeur

    # Calcul du revenu total du ménage
    total_income = user.revenu_demandeur
    if user.situation_familiale.in?(%w[marie cohabitant couple]) && user.revenu_conjoint
      total_income += user.revenu_conjoint
    end

    # Déductions Flandre : 4 320 € par personne à charge
    nb_charges = (user.nombre_enfants || 0)
    nb_charges += user.personnes_agees_charge if user.respond_to?(:personnes_agees_charge) && user.personnes_agees_charge
    deductions = nb_charges * 4_320
    adjusted_income = [total_income - deductions, 0].max

    # Seuils de revenu Flandre 2025 — catégorie 1 = revenus élevés, toujours éligible
    # En Flandre il n'y a pas de seuil d'inéligibilité, seulement des catégories
    # Toutes les catégories sont éligibles (la catégorie détermine le montant de la prime)
    { eligible: true }
  end

  def check_bruxelles_real_eligibility(user)
    # TODO: Implémenter la logique Bruxelles si nécessaire
    { eligible: true }
  end
end
