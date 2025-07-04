Rails.application.routes.draw do
  root "pages#home"

  resources :primes, only: [:index, :show]
  resources :categories, only: [:index, :show]

  # config/routes.rb
  post "/calcul-categorie", to: "categories#calcul"

end
