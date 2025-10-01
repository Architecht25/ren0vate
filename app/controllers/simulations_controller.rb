class SimulationsController < ApplicationController
  # Exemptions temporaires pour les tests (à sécuriser en production)
  skip_before_action :verify_authenticity_token, only: [:update_prime_inputs, :restore_prime_inputs]
  skip_before_action :authenticate_user!, only: [:show, :update_prime_inputs, :restore_prime_inputs]

  def index
    # Récupérer et trier les simulations par région (Flandre → Bruxelles → Wallonie)
    @simulations = Simulation.all.sort_by do |simulation|
      case simulation.region&.downcase
      when 'flandre' then 1
      when 'bruxelles' then 2
      when 'wallonie' then 3
      else 4 # Autres régions en dernier
      end
    end
  end

  def show
    @simulation = Simulation.find(params[:id])

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
    else
      @prime_cards = {}
      @total_amount = 0
    end

    # S'assurer que total_simule est cohérent avec les paramètres
    if @simulation.total_simule.nil? || @simulation.total_simule == 0
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

    # Calculer les économies vs chasseur de primes
    if @total_amount > 0 && @simulation.region.present?
      savings_calculator = SavingsCalculatorService.new(@total_amount, @simulation.region)
      @savings_data = savings_calculator.calculate_savings
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
    @simulation = Simulation.find(params[:id])
  end

  def update
    @simulation = Simulation.find(params[:id])
    if @simulation.update(simulation_params)
      redirect_to @simulation
    else
      render :edit
    end
  end

  def destroy
    @simulation = Simulation.find(params[:id])
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
    @simulation = Simulation.find(params[:id])
    perform_eligibility_test(@simulation)

    respond_to do |format|
      format.json {
        render json: {
          eligible: @simulation.eligible,
          message: @simulation.eligible? ? @simulation.category_description : @simulation.ineligibility_reason,
          next_step: @simulation.eligible? ? 'category' : nil
        }
      }
    end
  end

  # Nouveau endpoint pour l'éligibilité investissements (finalité économique)
  def check_eligibility_investment
    @simulation = Simulation.find(params[:id])
    perform_investment_eligibility_test(@simulation)

    respond_to do |format|
      format.json {
        render json: {
          eligible: @simulation.eligible_investment,
          message: @simulation.eligible_investment? ? "Éligible aux aides aux investissements" : @simulation.investment_ineligibility_reason,
          next_step: @simulation.eligible_investment? ? 'majorations' : nil
        }
      }
    end
  end

  # Nouveau endpoint pour l'éligibilité RENOLUTION (finalité économique)
  def check_eligibility_renolution
    @simulation = Simulation.find(params[:id])
    perform_renolution_eligibility_test(@simulation)

    respond_to do |format|
      format.json {
        render json: {
          eligible: @simulation.eligible_renolution,
          message: @simulation.eligible_renolution? ? "Éligible aux primes RENOLUTION" : @simulation.renolution_ineligibility_reason,
          next_step: @simulation.eligible_renolution? ? 'category' : nil
        }
      }
    end
  end

  def calculate_category
    @simulation = Simulation.find(params[:id])
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
    @simulation = Simulation.find(params[:id])

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
    @simulation = Simulation.find(params[:id])

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
    @simulation = Simulation.find(params[:id])

    # Permettre tous les paramètres user_inputs, gérer le cas des données vides pour l'auto-save
    user_inputs = if params[:user_inputs].present?
      params.require(:user_inputs).permit!.to_h
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
      # Si on a un total calculé côté client (pour Bruxelles/Wallonie), l'utiliser directement
      if calculated_total && calculated_total > 0 && %w[bruxelles wallonie].include?(@simulation.region&.downcase)
        Rails.logger.info "🚀 Utilisation du total côté client: #{calculated_total}€"

        # Mettre à jour directement le total
        @simulation.update!(total_simule: calculated_total)

        # Optionnel: aussi mettre à jour les paramètres pour la cohérence
        if @simulation.parameters.present?
          begin
            params_hash = JSON.parse(@simulation.parameters)
            params_hash["total_general"] = calculated_total
            params_hash["total"] = calculated_total
            params_hash["last_update"] = Time.current.iso8601
            @simulation.update!(parameters: params_hash.to_json)
          rescue JSON::ParserError
            # Ignorer si erreur de parsing
          end
        end

        # Calculer les économies vs chasseur de primes
        savings_data = nil
        if calculated_total > 0 && @simulation.region.present?
          savings_calculator = SavingsCalculatorService.new(calculated_total, @simulation.region)
          savings_data = savings_calculator.calculate_savings
        end

        render json: {
          success: true,
          total_amount: calculated_total,
          savings_data: savings_data,
          message: "Total mis à jour depuis côté client"
        }
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
        
        # Calculer les économies vs chasseur de primes
        savings_data = nil
        if result[:total_amount] && result[:total_amount] > 0 && @simulation.region.present?
          savings_calculator = SavingsCalculatorService.new(result[:total_amount], @simulation.region)
          savings_data = savings_calculator.calculate_savings
        end
        
        result[:savings_data] = savings_data
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
    @simulation = Simulation.find(params[:id])

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
            if prime["user_input_value"].present? && prime["user_input_value"] != 0 && prime["user_input_value"] != "0"
              user_inputs[prime["slug"]] = prime["user_input_value"]
            end
          end
        end
      end

      # Rails.logger.info "✅ Restored #{user_inputs.keys.length} user inputs for simulation #{@simulation.id}"
      render json: {
        success: true,
        user_inputs: user_inputs,
        total_amount: @simulation.total_simule,
        category: @simulation.category
      }

    rescue => e
      Rails.logger.error "❌ Exception in restore_prime_inputs: #{e.message}"
      Rails.logger.error "❌ Exception backtrace: #{e.backtrace.join("\n")}"
      render json: { success: false, error: "Erreur lors de la restauration: #{e.message}" }, status: :internal_server_error
    end
  end

  private

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
          project_id: simulation.project_id,
          simulation_type: params[:simulation_type] || 'particulier'
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

  # NOUVELLES MÉTHODES pour la double éligibilité (finalité économique)

  # Test d'éligibilité pour les investissements entreprise
  def perform_investment_eligibility_test(simulation)
    Rails.logger.info "=== PERFORM_INVESTMENT_ELIGIBILITY_TEST ==="

    return unless simulation.property.present? && simulation.project.present?
    return unless simulation.region&.downcase == 'bruxelles'
    return unless simulation.project.finalite_economique?

    # Utiliser le service d'éligibilité entreprise Bruxelles
    eligibility_service = Entreprises::BruxellesEntreprisesEligibilityService.new(current_user, {
      property_id: simulation.property_id,
      project_id: simulation.project_id
    })

    result = eligibility_service.check_eligibility

    if result[:eligible]
      simulation.update(
        eligible_investment: true
      )
    else
      simulation.update(
        eligible_investment: false,
        investment_ineligibility_reason: result[:message]
      )
    end
  end

  # Test d'éligibilité pour les primes RENOLUTION
  def perform_renolution_eligibility_test(simulation)
    Rails.logger.info "=== PERFORM_RENOLUTION_ELIGIBILITY_TEST ==="

    return unless simulation.property.present? && simulation.project.present?
    return unless simulation.region&.downcase == 'bruxelles'

    # Utiliser le service d'éligibilité Bruxelles classique (particulier)
    eligibility_service = Regions::Bruxelles::BruxellesEligibilityService.new(
      {
        property_id: simulation.property_id,
        project_id: simulation.project_id,
        simulation_type: 'particulier' # Force le type particulier pour RENOLUTION
      },
      user: current_user
    )

    result = eligibility_service.check_eligibility

    if result[:eligible]
      simulation.update(
        eligible_renolution: true
      )
    else
      simulation.update(
        eligible_renolution: false,
        renolution_ineligibility_reason: result[:message]
      )
    end
  end

  # ÉTAPE 2: Détermination de la catégorie
  def perform_category_determination(simulation)
    region = simulation.region&.downcase
    return unless simulation.eligible? && ['wallonie', 'flandre', 'bruxelles'].include?(region)

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
          project_id: simulation.project_id,
          simulation_type: params[:simulation_type] || 'particulier'
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
    elsif region == 'bruxelles'
      calculator_service = Regions::Bruxelles::BruxellesPostLoginCalculatorService.new(
        {
          property_id: simulation.property_id,
          project_id: simulation.project_id,
          simulation_type: params[:simulation_type] || 'particulier'
        },
        user: current_user
      )
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
      simulation.update(
        total_simule: cards_data[:total],
        parameters: {
          prime_cards: cards_data[:cards],
          total_general: cards_data[:total],
          category_used: cards_data[:category_used],
          calculation_timestamp: Time.current
        }.to_json
      )
    elsif region == 'flandre'
      simulation.update(
        total_simule: cards_data[:total_general],
        parameters: cards_data.to_json
      )
    elsif region == 'bruxelles'
      simulation.update(
        total_simule: cards_data[:total],
        parameters: {
          prime_cards: cards_data[:cards],
          total_general: cards_data[:total],
          category_used: cards_data[:category_used],
          calculation_timestamp: Time.current
        }.to_json
      )
    end
  end
end
