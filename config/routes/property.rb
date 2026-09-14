  resources :properties do
    member do
      get :dashboard  # Dashboard spécifique pour un bien
      get :documents_dashboard  # Gestion des documents par bien
      get :documents_phases_dashboard  # Nouveau dashboard par phases métier
      get :formulaire_miroir  # Formulaire miroir pré-rempli
      get :peb_recommandations  # Vue recommandations énergétiques PEB
      post :submit_prime  # Soumission vers l'administration
      delete :destroy  # Route de suppression explicite
      delete :purge_photo  # Suppression de la photo du bien

      # Mode vente & DIU
      get :mise_en_vente
      patch :activer_vente
      patch :desactiver_vente
      patch :marquer_vendu

      # Gestion locative
      get :gestion_locative
      get :profil_bailleur  # Tableau de bord dédié propriétaire-bailleur

      # Nouvelle route pour sélecteur formulaires
      get :select_form, to: 'requests#select_form'
    end

    collection do
      get :check_heritage  # Proxy vérification statut patrimonial Brussels
    end

    # Routes pour les requests liées à une propriété
    resources :requests, except: [:index, :show], shallow: true do
      member do
        patch :autosave  # Sauvegarde progressive AJAX
      end
    end
    # Documents liés à une propriété
    resources :documents, shallow: true
    # Gestion locative
    resources :tenants, except: [:index] do
      resources :leases, except: [:index] do
        member do
          patch :terminer
          patch :activer_resiliation
        end
        resources :rent_payments, except: [:show, :index]
      end
    end
    # Devis estimatifs
    resources :quotes, only: [:index, :new, :create, :show, :destroy] do
      collection do
        get :estimate
      end
      member do
        get  :print
        post :send_to_pro
      end
    end
  end
