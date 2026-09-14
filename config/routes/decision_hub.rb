  get '/conseil/:simulation_id', to: 'decision_hub#show', as: :decision_hub_short
  post '/conseil/:simulation_id/ia', to: 'decision_hub#ai_consultation', as: :decision_hub_ai

  # Decision Hub - Carrefour Conseil (page principale)
  resources :decision_hub, only: [:index] do
    collection do
      get :expert  # Assistant IA Expert dédié
      get :guide  # Guide d'utilisation
      get 'load_simulation/:simulation_id', to: 'decision_hub#load_simulation_data', as: 'load_simulation'
      post 'ai_consultation/:simulation_id', to: 'decision_hub#ai_consultation', as: 'ai_consultation'
      post :save_technical_preparation  # Sauvegarde des données techniques
    end
  end
