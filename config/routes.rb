Rails.application.routes.draw do
  devise_for :users
  root "pages#home"

  # Dashboard routes
  get '/dashboard', to: 'dashboard#index', as: :dashboard

  # Regulatory Requirements - Base de connaissance réglementaire
  resources :regulatory_requirements, only: [:index] do
    collection do
      get :ventilation_guide
      get :ventilation_calculator
      get :region_selection  # Page de sélection de région
    end
  end

  resources :primes
  resources :categories

  # Documents avec routes spéciales pour download et contexte
  resources :documents do
    member do
      get :download
      get :preview
    end
  end

  resources :notifications
  resources :properties do
    member do
      get :dashboard  # Dashboard spécifique pour un bien
      get :debug_completion  # Route de debug temporaire
      get :documents_dashboard  # Gestion des documents par bien
      get :formulaire_miroir  # Formulaire miroir pré-rempli
      post :submit_prime  # Soumission vers l'administration
    end
    # Documents liés à une propriété
    resources :documents, shallow: true
  end

  resources :projects do
    # Documents liés à un chantier
    resources :documents, shallow: true
  end

  resources :referrals

  resources :requests do
    # Documents liés à une demande
    resources :documents, shallow: true
  end

  resources :simulations do
    # Documents liés à une simulation
    resources :documents, shallow: true
  end

  resources :users
  resources :work

  # config/routes.rb
  post "/calcul-categorie", to: "categories#calcul"
  get '/admin/dashboard', to: 'admin#dashboard'
  get    "/profil",           to: "users#profile", as: :profile
  get    "/profile",          to: redirect("/profil")  # Redirection EN -> FR
  get    "/profil/edition",   to: "users#edit",    as: :edit_profile
  patch  "/profil",           to: "users#update"

  get '/flandre', to: 'pages#flandre', as: :flandre
  get '/wallonie', to: 'pages#wallonie', as: :wallonie
  get '/bruxelles', to: 'pages#bruxelles', as: :bruxelles
  get '/mentions-legales', to: 'pages#legal', as: :legal
  get '/politique-de-confidentialite', to: 'pages#privacy', as: :privacy

  # Route de debug temporaire
  get '/debug/properties', to: 'debug#properties' if Rails.env.development?
end
