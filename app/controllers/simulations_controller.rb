class SimulationsController < ApplicationController
  def index
    @simulations = Simulation.all
  end

  def show
    @simulation = Simulation.find(params[:id])
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
    @simulation.destroy
    redirect_to simulations_path
  end

  private

  def simulation_params
    params.require(:simulation).permit(:titre, :region, :parameters, :property_id, :user_id,
                                       :eligible, :category, :category_description, :ineligibility_reason)
  end

  # ÉTAPE 1: Test d'éligibilité (méthode stub à implémenter)
  def perform_eligibility_test(simulation)
    # TODO: Implémenter la logique de test d'éligibilité
    # Pour l'instant, on peut définir comme éligible par défaut pour tester l'interface

    # Exemple de logique simple (à remplacer par la vraie logique métier)
    if simulation.region.present? && simulation.property.present?
      simulation.update(
        eligible: true
      )
      # Déclencher l'étape 2
      perform_category_determination(simulation)
    else
      simulation.update(
        eligible: false,
        ineligibility_reason: "Région ou propriété manquante"
      )
    end
  end

  # ÉTAPE 2: Détermination de la catégorie (méthode stub à implémenter)
  def perform_category_determination(simulation)
    # TODO: Implémenter la logique de détermination de catégorie

    # Exemple de logique simple basée sur la région
    category_info = case simulation.region
                   when 'wallonie'
                     {
                       category: 'Rénovation énergétique Wallonie',
                       description: 'Primes pour travaux d\'isolation et d\'efficacité énergétique en Wallonie'
                     }
                   when 'flandre'
                     {
                       category: 'Woningrenovatiepremie Vlaanderen',
                       description: 'Subsidies voor energiebesparende renovaties in Vlaanderen'
                     }
                   when 'bruxelles'
                     {
                       category: 'Primes énergie Bruxelles',
                       description: 'Primes de la région bruxelloise pour l\'amélioration énergétique'
                     }
                   else
                     {
                       category: 'Général',
                       description: 'Catégorie générale'
                     }
                   end

    simulation.update(
      category: category_info[:category],
      category_description: category_info[:description]
    )

    # Déclencher l'étape 3
    perform_prime_calculation(simulation)
  end

  # ÉTAPE 3: Calcul des primes (méthode stub à implémenter)
  def perform_prime_calculation(simulation)
    # TODO: Implémenter la logique de calcul des primes

    # Pour l'instant, créer quelques primes d'exemple pour tester l'interface
    # (à remplacer par la vraie logique de calcul)

    # Exemple de création de primes factices
    if simulation.category.present?
      create_example_prime_cards(simulation)
    end
  end

  # Méthode d'exemple pour créer des cartes primes factices (à supprimer plus tard)
  def create_example_prime_cards(simulation)
    # Prime d'exemple 1
    if Prime.exists?
      prime1 = Prime.first
      simulation.simulation_prime_cards.create!(
        prime: prime1,
        montant: 1500,
        calcul_details: "Surface isolation: 50m² × 30€/m² = 1500€"
      )
    end

    # Vous pouvez ajouter d'autres primes d'exemple ici
  end
end
