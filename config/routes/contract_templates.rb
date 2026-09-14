  resources :contract_templates, only: [:index, :show] do
    member do
      get :download
      get :preview
    end
  end
