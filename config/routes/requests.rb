  resources :requests do
    # Documents liés à une demande
    resources :documents, shallow: true

    # Suivis de demandes de primes
    resources :request_progresses, except: [:destroy], shallow: true

    member do
      patch :autosave  # Endpoint pour l'auto-save AJAX
    end

    collection do
      # Primes communales Bruxelles : pas de formulaire dédié (dépôt via le site communal),
      # crée juste le dossier minimal nécessaire pour activer le suivi (étape 4)
      post :create_communal_bruxelles
    end
  end
