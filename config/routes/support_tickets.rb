  resources :support_tickets, only: [:index, :new, :create, :show] do
    member do
      post :reply
      patch :close
    end
  end
