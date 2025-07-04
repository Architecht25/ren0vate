Rails.application.routes.draw do
  root "pages#home"

  resources :primes, only: [:index, :show]
  resources :categories, only: [:index, :show]
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
end
