module BruxellesPrimesHelper
  # Cache les primes Bruxelles pour éviter les requêtes répétées
  def bruxelles_primes_cache
    @bruxelles_primes_cache ||= Prime.where(region: "bruxelles").index_by(&:slug)
  end

  # Récupère la condition d'une prime par son slug
  def condition_prime(slug)
    prime = bruxelles_primes_cache[slug]
    prime&.condition || ""
  end

  # Récupère le conseil d'une prime par son slug
  def conseil_prime(slug)
    prime = bruxelles_primes_cache[slug]
    prime&.conseil || ""
  end

  # Génère les données JSON des primes pour le JavaScript
  def bruxelles_primes_data_json
    bruxelles_primes_cache.transform_values do |prime|
      {
        nom: prime.titre,
        valeurs_par_categorie: {
          "bruxelles_cat1" => prime.valeurs_par_categorie&.dig("bruxelles_cat1") || {},
          "bruxelles_cat2" => prime.valeurs_par_categorie&.dig("bruxelles_cat2") || {},
          "bruxelles_cat3" => prime.valeurs_par_categorie&.dig("bruxelles_cat3") || {}
        }
      }
    end.to_json
  end
end
