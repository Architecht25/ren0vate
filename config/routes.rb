Rails.application.routes.draw do
  # Routes Devise en dehors du scope pour éviter les problèmes de mapping
  devise_for :users, path_names: {
    sign_in: 'connexion',
    sign_out: 'deconnexion',
    sign_up: 'inscription'
  }

  # Routes avec support multi-langues
  scope "(:locale)", locale: /fr|nl|en/ do
    root "pages#home"

    # API routes for enterprise aids
    namespace :api do
      get 'entreprises/bce/:numero_bce', to: 'entreprises#bce_lookup'
      get 'entreprises/bruxelles/aides', to: 'entreprises#bruxelles_aides'

      # API pour les préférences utilisateur
      patch 'users/language-preference', to: 'users#update_language_preference'

      # Routes API pour la sécurité
      get 'security/headers_check'
      get 'security/csp_violations'
      get 'security/security_overview'
    end

    # Dashboard routes
    get '/dashboard', to: 'dashboard#index', as: :dashboard

    # Test I18n route
    get '/i18n-test', to: 'i18n_test#index', as: :i18n_test

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
    # API BCE pour recherche d'entreprises
    post 'bce/search', to: 'bce#search'

    # API Aides Bruxelles pour entreprises
    get 'bruxelles_aides/categories', to: 'bruxelles_aides#categories'
    get 'bruxelles_aides/categories/:category_id', to: 'bruxelles_aides#category_details'

    # API Calculs Flandre
    post 'flandre/calculate_prime', to: 'flandre_calculations#calculate_prime'
    post 'flandre/calculate_all', to: 'flandre_calculations#calculate_all'

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

  # Documents officiels des primes (attestations, formulaires, etc.)
  resources :prime_document_templates, only: [:index, :show] do
    member do
      get :download
    end
  end

  # Routes pour téléchargement groupé de documents
  get 'primes/:id/download_documents', to: 'prime_document_templates#download_prime_documents', as: :download_documents_prime
  get 'simulations/:simulation_id/download_documents', to: 'prime_document_templates#download_simulation_documents', as: :download_documents_simulation

  resources :notifications, only: [:index, :show] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
      get :new_admin
      post :create_admin
      post :generate_automatic
    end
  end
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
    member do
      post :check_eligibility  # Étape 1: Vérification éligibilité
      post :calculate_category  # Étape 2: Calcul de catégorie
      post :calculate_primes    # Étape 3: Calcul des primes
      patch :update_prime_inputs # Sauvegarde des saisies utilisateur
      get :test_autosave       # Page de test pour l'auto-save
    end
    # Documents liés à une simulation
    resources :documents, shallow: true
  end

  resources :users

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

  # Pages d'information sur les aides aux entreprises (autres régions)
  get '/flandre-entreprises', to: 'pages#flandre_entreprises', as: :flandre_entreprises
  get '/wallonie-entreprises', to: 'pages#wallonie_entreprises', as: :wallonie_entreprises
  get '/mentions-legales', to: 'pages#legal', as: :legal
  get '/politique-de-confidentialite', to: 'pages#privacy', as: :privacy

  end # Fin du scope locale

  # Route pour les rapports de violation CSP (hors scope locale)
  post '/csp-violation-report-endpoint', to: 'security#csp_violation_report'

  # Route de redirection pour les URLs sans locale
  get '/*path', to: redirect("/fr/%{path}"), constraints: lambda { |req| !req.path.starts_with?("/fr") && !req.path.starts_with?("/nl") && !req.path.starts_with?("/en") }
end
