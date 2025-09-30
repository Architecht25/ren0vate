module FlandrePrimesHelper
  # Helper pour récupérer la condition d'une prime depuis la base de données
  def condition_prime(slug)
    prime = Prime.find_by(slug: slug)
    prime&.condition || "Conditions en cours de chargement..."
  end

  # Helper pour récupérer le conseil d'une prime depuis la base de données
  def conseil_prime(slug)
    prime = Prime.find_by(slug: slug)
    prime&.conseil || "Conseil en cours de chargement..."
  end

  # Helper pour préparer les valeurs sauvegardées pour restauration
  def prepare_saved_flandre_inputs(simulation)
    saved_inputs = {}
    return saved_inputs unless simulation.parameters.present?

    begin
      params_data = JSON.parse(simulation.parameters)
      if params_data['prime_cards'].present?
        # Récupérer les slugs des primes Flandre pour filtrer
        flandre_slugs = Prime.where(region: 'flandre').pluck(:slug)

        params_data['prime_cards'].each do |category_key, category_data|
          next unless category_data['primes']

          category_data['primes'].each do |prime|
            # Filtrer pour ne garder que les primes Flandre
            next unless flandre_slugs.include?(prime['slug'])

            if prime['user_input_value'].present? &&
               prime['user_input_value'] != 0 &&
               prime['user_input_value'] != "0"
              saved_inputs[prime['slug']] = prime['user_input_value']
            end
          end
        end
      end
    rescue JSON::ParserError
      # Si le JSON est invalide, on ignore et retourne un hash vide
    end

    saved_inputs
  end

  # Helper pour générer les données JSON des primes Flandre
  def flandre_primes_data
    Prime.where(region: "flandre").map do |prime|
      [prime.slug, {
        nom: prime.titre,
        valeurs_par_categorie: prime.valeurs_par_categorie || {},
        placeholder: prime.placeholder || {}
      }]
    end.to_h
  end

  # Helper pour générer les données de simulation
  def simulation_category_data(simulation)
    {
      category: simulation.category,
      simulationId: simulation.id,
      region: "flandre"
    }
  end
end
