    namespace :api do
      # API Bot Contextuel (Claude)
      post 'contextual_bot/chat',          to: 'contextual_bot#chat'
      post 'contextual_bot/suggestions',   to: 'contextual_bot#suggestions'
      post 'contextual_bot/message',       to: 'contextual_bot#chat'       # alias pour decision_hub/expert
      post 'contextual_bot/clear_history', to: 'contextual_bot#clear_history'

      # API pour génération d'aperçus PDF asynchrones
      post 'pdf_preview/:id/generate', to: 'pdf_preview#generate', as: 'generate_pdf_preview'

      # IA #4 — Prédicteur Permis d'Urbanisme
      post 'permis_predicator/:project_id', to: 'permis_predicator#predict', as: 'permis_predicator'

      # API pour les primes communales Flandre
      resources :primes_communales, only: [] do
        collection do
          get :index          # GET /api/primes_communales?code_postal=9000
          post :calculate     # POST /api/primes_communales/calculate
          get :communes       # GET /api/primes_communales/communes
          get :search         # GET /api/primes_communales/search?q=isolation
          get :categories     # GET /api/primes_communales/categories
          get :stats          # GET /api/primes_communales/stats
        end
      end

      # API pour les primes communales Bruxelles
      resources :primes_communales_bruxelles, only: [] do
        collection do
          get :index          # GET /api/primes_communales_bruxelles?code_postal=1000
          post :calculate     # POST /api/primes_communales_bruxelles/calculate
          get :communes       # GET /api/primes_communales_bruxelles/communes
          get :search         # GET /api/primes_communales_bruxelles/search?q=isolation
          get :categories     # GET /api/primes_communales_bruxelles/categories
          get :stats          # GET /api/primes_communales_bruxelles/stats
        end
      end

      # API pour les primes communales Wallonie
      resources :primes_communales_wallonie, only: [] do
        collection do
          get :index          # GET /api/primes_communales_wallonie?code_postal=4000
          post :calculate     # POST /api/primes_communales_wallonie/calculate
          get :communes       # GET /api/primes_communales_wallonie/communes
          get :search         # GET /api/primes_communales_wallonie/search?q=isolation
          get :metadata       # GET /api/primes_communales_wallonie/metadata
        end
      end

      # API pour les préférences utilisateur
      patch 'users/language-preference', to: 'users#update_language_preference'

      # Routes API pour la sécurité (dashboard admin — Api::SecurityMonitoringController,
      # à ne pas confondre avec SecurityController à la racine qui reçoit les rapports
      # CSP publics du navigateur sur /csp-violation-report-endpoint)
      get 'security/headers_check',     to: 'security_monitoring#headers_check'
      get 'security/csp_violations',    to: 'security_monitoring#csp_violations'
      get 'security/security_overview', to: 'security_monitoring#security_overview'

      # API Calculs Flandre
      post 'flandre/calculate_prime', to: 'flandre_calculations#calculate_prime'
      post 'flandre/calculate_all', to: 'flandre_calculations#calculate_all'

      # NPS / feedback utilisateur
      post 'nps', to: 'nps#create'
    end
