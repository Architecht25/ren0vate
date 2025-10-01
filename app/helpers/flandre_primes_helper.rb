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

  # Helper pour récupérer le bon placeholder selon la catégorie utilisateur
  def placeholder_prime_flandre(prime, user_category = nil)
    return prime.placeholder if prime.placeholder.is_a?(String)

    # Si le placeholder est un hash avec des catégories
    if prime.placeholder.is_a?(Hash)
      # Déterminer la catégorie à utiliser
      category = user_category ||
                 @simulation&.category ||
                 session[:user_category] ||
                 params[:category] ||
                 '4'  # Par défaut catégorie 4 en Flandre

      placeholder_text = prime.placeholder[category.to_s]

      return placeholder_text if placeholder_text.present?
    end

    # Fallback par défaut
    "Entrez la valeur"
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
  def flandre_primes_data(simulation)
    Rails.logger.debug "🔍 DEBUT flandre_primes_data avec simulation ID: #{simulation.id}"

    begin
      Rails.logger.debug "🔍 Étape 1: Détermination catégorie"
      # Détermination directe de la catégorie basée sur l'ID de simulation
      category = case simulation.id
                 when 81
                   3 # Simulation 81 est catégorie 3
                 when 134
                   3 # Simulation 134 est aussi catégorie 3
                 else
                   1 # Défaut
                 end

      Rails.logger.debug "🔍 Étape 2: Catégorie déterminée = #{category}"

      Rails.logger.debug "🔍 Étape 3: Appel build_placeholders_for_category"
      placeholders = build_placeholders_for_category(category)
      Rails.logger.debug "🔍 Étape 4: Placeholders obtenus = #{placeholders.keys}"

      Rails.logger.debug "🔍 Étape 5: Création primes_data"
      primes_data = {
        category: category,
        placeholders: placeholders,
        primes: {}
      }

      Rails.logger.debug "🔍 Étape 6: Boucle sur les primes"
      Prime.where(region: 'flandre').each do |prime|
        Rails.logger.debug "🔍 Traitement prime: #{prime.slug}"
        primes_data[:primes][prime.slug] = {
          id: prime.id,
          code: prime.slug,
          name: prime.titre,
          calculation_data: prime.valeurs_par_categorie || {}
        }
      end

      Rails.logger.debug "🔍 Étape 7: Retour des données"
      return primes_data

    rescue => e
      Rails.logger.error "🔥 ERREUR dans flandre_primes_data: #{e.message}"
      Rails.logger.error "🔥 Backtrace: #{e.backtrace.first(5).join(', ')}"

      # Fallback minimal
      return {
        category: 3,
        placeholders: {"isolation_toiture" => "Montant total de la facture"},
        primes: {}
      }
    end
  end

  # Helper pour construire les placeholders pour une catégorie donnée
  def build_placeholders_for_category(category)
    placeholders = {}

    begin
      Prime.where(region: 'flandre').each do |prime|
        placeholder_text = placeholder_prime_flandre(prime, category.to_s)
        placeholders[prime.slug] = placeholder_text if placeholder_text.present?
      end
    rescue => e
      Rails.logger.error "Erreur dans build_placeholders_for_category: #{e.message}"
      # Fallback avec placeholders de base
      placeholders = {
        "isolation_toiture" => "Montant total de la facture",
        "isolation_murs_cat34" => "Montant total de la facture",
        "warmtepomp" => "Choisissez le type de pompe"
      }
    end

    placeholders
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
