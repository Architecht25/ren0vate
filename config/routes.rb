Rails.application.routes.draw do
  devise_for :users
  root "pages#home"

  resources :primes
  resources :categories
  resources :documents
  resources :notifications
  resources :properties
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
  end

  get '/flandre', to: 'pages#flandre', as: :flandre
  get '/wallonie', to: 'pages#wallonie', as: :wallonie
  get '/bruxelles', to: 'pages#bruxelles', as: :bruxelles
  get '/mentions-legales', to: 'pages#legal', as: :legal
  get '/politique-de-confidentialite', to: 'pages#privacy', as: :privacy
end
