  resources :requests do
    # Documents liés à une demande
    resources :documents, shallow: true

    # Suivis de demandes de primes
    resources :request_progresses, except: [:destroy], shallow: true

    member do
      patch :autosave  # Endpoint pour l'auto-save AJAX
    end
  end
