  resources :simulations do
    member do
      post :check_eligibility  # Étape 1: Vérification éligibilité
      post :calculate_category  # Étape 2: Calcul de catégorie
      post :calculate_primes    # Étape 3: Calcul des primes
      post :calculate_prime     # Calcul d'une prime individuelle
      patch :update_prime_inputs # Sauvegarde des saisies utilisateur
      get :restore_prime_inputs # Restauration des saisies utilisateur
      patch :save_total         # Sauvegarde du total global calculé côté client

      # Decision Hub - Carrefour Conseil IA
      get :decision_hub  # Vue principale du carrefour conseil
      post :ai_consultation  # Endpoint pour les questions IA
    end
    # Documents liés à une simulation
    resources :documents, shallow: true
  end
