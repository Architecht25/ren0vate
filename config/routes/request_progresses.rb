  resources :request_progresses, only: [:index, :show, :edit, :update, :destroy] do
    member do
      patch :upload_document  # Upload de documents de suivi
      patch :update_status_by_email  # Mise à jour par email de suivi
    end
  end
