class SimulationsController < ApplicationController
  def index
    @simulations = Simulation.all
  end

  def show
    @simulation = Simulation.find(params[:id])

    # Extraire les données des primes et le total depuis les paramètres
    if @simulation.parameters.present?
      params_data = JSON.parse(@simulation.parameters)
      @prime_cards = params_data['prime_cards'] || []
      @total_amount = @simulation.total_simule || 0
    else
      @prime_cards = []
      @total_amount = 0
    end

    # Rendre les variables disponibles dans la vue
    prime_cards = @prime_cards
    total_amount = @total_amount
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
          params_data = @simulation.parameters ? JSON.parse(@simulation.parameters) : {}
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

  def update_prime_inputs
    @simulation = Simulation.find(params[:id])
    user_inputs = params[:user_inputs] || {}

    Rails.logger.info "Updating prime inputs for simulation #{@simulation.id} with #{user_inputs.keys.length} inputs"

    begin
      # Récupérer les paramètres existants
      current_params = @simulation.parameters ? JSON.parse(@simulation.parameters) : {}

      # Mettre à jour les saisies utilisateur
      current_params['user_inputs'] = user_inputs
      current_params['last_input_update'] = Time.current

      # Recalculer les montants avec les nouvelles saisies
      updated_totals = {}
      if @simulation.category.present?
        updated_totals = recalculate_with_user_inputs(user_inputs)
        current_params.merge!(updated_totals)
      end

      # Sauvegarder de manière optimisée
      @simulation.update_columns(
        parameters: current_params.to_json,
        total_simule: current_params['total_general'],
        updated_at: Time.current
      )

      Rails.logger.info "Successfully updated simulation #{@simulation.id}, new total: #{current_params['total_general']}"

      respond_to do |format|
        format.json {
          render json: {
            success: true,
            user_inputs: user_inputs,
            total_amount: current_params['total_general'],
            updated_cards: current_params['prime_cards'],
            calculation_time: Time.current.strftime('%H:%M:%S')
          }
        }
      end

    rescue StandardError => e
      Rails.logger.error "Error updating prime inputs for simulation #{@simulation.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      respond_to do |format|
        format.json {
          render json: {
            success: false,
            error: "Erreur lors du calcul: #{e.message}"
          }, status: :internal_server_error
        }
      end
    end
  end

  private

  # Méthode optimisée pour recalculer avec les saisies utilisateur
  def recalculate_with_user_inputs(user_inputs)
    return {} unless @simulation.category.present?

    Rails.logger.info "Recalculating with #{user_inputs.keys.length} user inputs for category #{@simulation.category}"

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

      Rails.logger.info "Calculation completed in #{calculation_time.round(3)}s for #{cards_data[:prime_cards]&.keys&.length || 0} categories"

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
    Rails.logger.info "=== PERFORM_ELIGIBILITY_TEST ==="
    Rails.logger.info "Simulation ID: #{simulation.id}, region: '#{simulation.region}'"
    Rails.logger.info "Property present: #{simulation.property.present?}"

    region = simulation.region&.downcase

    unless ['wallonie', 'flandre'].include?(region)
      Rails.logger.info "SKIPPED: Region '#{simulation.region}' is not supported yet"
      return
    end

    unless simulation.property.present?
      Rails.logger.info "SKIPPED: No property associated"
      return
    end

    Rails.logger.info "Proceeding with eligibility test for region: #{region}"
    Rails.logger.info "📋 Simulation property_id: #{simulation.property_id}"
    Rails.logger.info "📋 Simulation project_id: #{simulation.project_id}"

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
    end

    result = eligibility_service.check_eligibility

    if result[:eligible]
      simulation.update(
        eligible: true,
        category_description: result[:message]
      )
      # Déclencher l'étape 2 automatiquement pour Wallonie et Flandre
      perform_category_determination(simulation) if ['wallonie', 'flandre'].include?(region)
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
    end

    result = category_service.determine_category

    if result[:eligible]
      simulation.update(
        category: result[:category],
        category_description: result[:details]
      )
      # Déclencher l'étape 3 automatiquement
      perform_primes_calculation(simulation)
    else
      # Si non éligible au niveau catégorie, mise à jour de l'éligibilité globale
      simulation.update(
        eligible: false,
        ineligibility_reason: result[:error] || "Non éligible pour les primes"
      )
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
    end
  end
end
