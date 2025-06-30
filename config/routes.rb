Rails.application.routes.draw do
  root "pages#home"
  resources :primes, only: [:index, :show]
end
