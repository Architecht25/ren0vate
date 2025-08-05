Rails.application.routes.draw do
  devise_for :users
  root "pages#home"

  # Dashboard routes
  get '/dashboard', to: 'dashboard#index', as: :dashboard

  # Regulations - Base de connaissance réglementaire
  resources :regulations, only: [:index] do
    collection do
      get :ventilation_guide
      get :ventilation_calculator
      get :region_selection  # Page de sélection de région
    end
  end

  resources :primes
  resources :categories

  # Routes de test pour la nouvelle architecture de calculs
  get '/test/wallonie', to: 'calculations#test_wallonie'
  get '/test/bruxelles', to: 'calculations#test_bruxelles'

  # API pour calculs de primes
  namespace :api do
    namespace :v1 do
      namespace :wallonie do
        post 'check_eligibility', to: 'calculations#check_eligibility'
        post 'calculate_primes', to: 'calculations#calculate_primes'
        post 'get_category', to: 'calculations#get_category'
      end
    end

    # API BCE
    post '/bce/search', to: 'bce#search'
  end

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
      get :documents_dashboard  # Gestion des documents par bien
      get :formulaire_miroir  # Formulaire miroir pré-rempli
      post :submit_prime  # Soumission vers l'administration
      delete :destroy  # Route de suppression explicite
    end
    # Documents liés à une propriété
    resources :documents, shallow: true
  end

  # Routes simples pour tous les projets/chantiers
  resources :projects do
    # Documents liés à un chantier
    resources :documents, shallow: true
  end

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
  get '/wallonie/select-profile', to: 'pages#select_profile_wallonie'
  post '/wallonie/select-profile', to: 'pages#select_profile_wallonie', as: :select_profile_wallonie
  post '/wallonie/test-eligibility', to: 'pages#test_eligibility_wallonie', as: :test_eligibility_wallonie
  post '/wallonie/estimate-category', to: 'pages#estimate_category_wallonie', as: :estimate_category_wallonie
  get '/bruxelles', to: 'pages#bruxelles', as: :bruxelles
  post '/bruxelles/select-profile', to: 'pages#select_profile_bruxelles', as: :select_profile_bruxelles
  post '/bruxelles/test-eligibility', to: 'pages#test_eligibility_bruxelles', as: :test_eligibility_bruxelles
  post '/bruxelles/estimate-category', to: 'pages#estimate_category_bruxelles', as: :estimate_category_bruxelles

  # Nouveau simulateur : Aides aux entreprises Bruxelles
  get '/bruxelles-entreprises', to: 'pages#bruxelles_entreprises', as: :bruxelles_entreprises
  post '/bruxelles-entreprises/test-eligibility', to: 'pages#test_eligibility_bruxelles_entreprises', as: :test_eligibility_bruxelles_entreprises
  get '/mentions-legales', to: 'pages#legal', as: :legal
  get '/politique-de-confidentialite', to: 'pages#privacy', as: :privacy
end
