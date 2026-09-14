  namespace :admin do
    # Blog — gestion des articles
    resources :articles do
      member do
        post :publish
        post :unpublish
      end
    end

    # Gestion des utilisateurs pour les administrateurs
    resources :users do
      member do
        get :details        # AJAX endpoint pour charger les détails
        get :documents      # Voir tous les documents d'un utilisateur
        get :properties     # Voir toutes les propriétés d'un utilisateur
        get :projects       # Voir tous les projets d'un utilisateur
        post :impersonate             # Se connecter en tant qu'utilisateur (loggé dans AdminAuditLog)
        post :toggle_primes_services  # Basculer le flag client Primes-Services
        post :mark_contacted          # Marquer un lead comme contacté (suivi relance à 7 jours)
      end
    end

    delete "stop_impersonating", to: "users#stop_impersonating", as: :stop_impersonating

    # Propriétés — vue détaillée admin
    resources :properties, only: [:show]

    # Support tickets — admin
    resources :support_tickets, only: [:index, :show] do
      member do
        post :reply
        patch :resolve
        patch :close
      end
    end

    # Veille intelligence — rapports hebdomadaires IA
    resources :intelligence_reports, only: [:index, :show] do
      collection do
        post :run
      end
    end

    # Veille presse — articles importés manuellement pour le contexte IA
    resources :veille_articles do
      member do
        post :toggle_active
      end
    end

    # Veille réglementaire — pages officielles surveillées (RegulatoryWatchJob)
    resources :regulatory_sources, only: [:index] do
      collection do
        post :check_now
      end
    end

    # Marketing — drafts générés par l'Agent Marketing
    resources :marketing_weeks, only: [:index, :show, :destroy] do
      member do
        patch :mark_reviewed
        patch :mark_published
      end
    end
  end
