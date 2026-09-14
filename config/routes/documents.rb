  # Documents avec routes spéciales pour download et contexte
  resources :documents do
    member do
      get :download
      get :preview
      get :view
      get :debug
      get :ocr_view
      patch :rename
    end
    collection do
      get    :photos          # Galerie photos de suivi (sidebar section 6)
      get    :download_zip    # Télécharger toutes les photos (ou la sélection) en ZIP — contexte projet/bien/global
      delete :destroy_multiple # Suppression groupée de documents
    end
  end
