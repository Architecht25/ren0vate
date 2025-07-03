Rails.application.routes.draw do
  get "categories/index"
  get "categories/show"
  root "pages#home"
  resources :primes, only: [:index, :show]
  resources :categories, only: [:index, :show]
end
