Rails.application.routes.draw do
  root "pages#home"
  
  resources :primes, only: [:index, :show]
  resources :categories, only: [:index, :show]
end
