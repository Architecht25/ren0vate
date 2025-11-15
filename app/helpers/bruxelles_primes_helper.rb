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

  # Call-to-action pour inciter à la connexion au lieu du conseil générique
  def conseil_prime(slug)
    "Explications détaillées, démarches et conseils d'expert disponibles dans l'application. #{link_to 'Se connecter', new_user_session_path, class: 'text-decoration-none fw-bold'} ou #{link_to 'créer un compte', new_user_registration_path, class: 'text-decoration-none fw-bold'}.".html_safe
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
