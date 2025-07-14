Rails.application.routes.draw do
  devise_for :users
  root "pages#home"

  # Dashboard routes
  get '/dashboard', to: 'dashboard#index', as: :dashboard

  resources :primes
  resources :categories
  resources :documents
  resources :notifications
  resources :properties do
    member do
      get :dashboard  # Dashboard spécifique pour un bien
      get :documents_dashboard  # Gestion des documents par bien
      get :formulaire_miroir  # Formulaire miroir pré-rempli
      post :submit_prime  # Soumission vers l'administration
    end
  end
  resources :projects
  resources :referrals
  resources :requests
  resources :simulations
  resources :users
  resources :work

  # config/routes.rb
  post "/calcul-categorie", to: "categories#calcul"
  get '/admin/dashboard', to: 'admin#dashboard'
  get '/localstorage', to: 'localstorage#index'
  get    "/profil",           to: "users#profile", as: :profile
  get    "/profil/edition",   to: "users#edit",    as: :edit_profile
  patch  "/profil",           to: "users#update"

  namespace :api do
    post 'save_localstorage', to: 'localstorage#save'
    post 'send_results_email', to: 'localstorage#send_results_email'
  end

  get '/flandre', to: 'pages#flandre', as: :flandre
  get '/wallonie', to: 'pages#wallonie', as: :wallonie
  get '/bruxelles', to: 'pages#bruxelles', as: :bruxelles
  get '/mentions-legales', to: 'pages#legal', as: :legal
  get '/politique-de-confidentialite', to: 'pages#privacy', as: :privacy

  # Route de debug temporaire
  get '/debug/properties', to: 'debug#properties' if Rails.env.development?
end
