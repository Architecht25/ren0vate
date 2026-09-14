  resources :notifications, only: [:index, :show, :new, :create, :destroy] do
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
