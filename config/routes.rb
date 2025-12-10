Rails.application.routes.draw do
  # Routes ActionMailbox pour la réception d'emails
  mount ActionMailbox::Engine => '/rails/action_mailbox'

  # Redirections pour les anciennes routes Devise vers les nouvelles avec locale
  get '/inscription', to: redirect('/fr/users/inscription')
  get '/connexion', to: redirect('/fr/users/connexion')

  # Routes avec support multi-langues (y compris Devise)
  scope "(:locale)", locale: /fr|nl|en/ do
    # Routes Devise dans le scope locale avec contrôleur personnalisé
    devise_for :users, path_names: {
      sign_in: 'connexion',
      sign_out: 'deconnexion',
      sign_up: 'inscription'
    }, controllers: {
      sessions: 'users/sessions'
    }

    root "pages#home"

  # Pricing routes
  get '/pricing', to: 'pricing#index'
  get '/pricing/select', to: 'pricing#select'
  get '/pricing/summary/:tier', to: 'pricing#summary', as: 'pricing_summary'
  post '/pricing/checkout', to: 'pricing#checkout'
  get '/pricing/success', to: 'pricing#success'
  get '/pricing/cancel', to: 'pricing#cancel'

  # Webhook routes
  post '/webhooks/stripe', to: 'webhooks#stripe'

  # PDF Export routes
  post 'pdf_exports/eligibilite', to: 'pdf_exports#export_eligibilite'
  post 'pdf_exports/primes', to: 'pdf_exports#export_primes'
  post 'pdf_exports/complet', to: 'pdf_exports#export_complet'

  # Test page for PDF export
  get 'test/pdf_export', to: 'pages#test_pdf_export'
  get 'test/responsive', to: 'pages#test_responsive'

    # API routes for enterprise aids
    namespace :api do
      get 'entreprises/bce/:numero_bce', to: 'entreprises#bce_lookup'
      post 'entreprises/bce_lookup', to: 'entreprises#bce_lookup'
      get 'entreprises/bruxelles/aides', to: 'entreprises#bruxelles_aides'
      post 'entreprises/bruxelles/majorations', to: 'entreprises#calculate_bruxelles_majorations'
      get 'entreprises/bruxelles/majorations-details', to: 'entreprises#get_majorations_details'

      # API Bot Contextuel
      post 'contextual_bot/chat', to: 'contextual_bot#chat'
      post 'contextual_bot/suggestions', to: 'contextual_bot#suggestions'

      # API pour génération d'aperçus PDF asynchrones
      post 'pdf_preview/:id/generate', to: 'pdf_preview#generate', as: 'generate_pdf_preview'      # API pour les primes communales Flandre
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

      # Routes API pour la sécurité
      get 'security/headers_check'
      get 'security/csp_violations'
      get 'security/security_overview'
    end

    # Dashboard routes
    get '/dashboard', to: 'dashboard#index', as: :dashboard

  # Regulations - Base de connaissance réglementaire
  resources :regulations, only: [:index] do
    collection do
      get :ventilation_guide
      get :ventilation_calculator
      get :region_selection  # Page de sélection de région
    end
  end

  resources :primes
  resources :entreprise_aides, path: 'entreprises/aides', only: [:show]
  resources :categories

  # Routes de test pour la nouvelle architecture de calculs
  get '/test/wallonie', to: 'calculations#test_wallonie'
  get '/test/bruxelles', to: 'calculations#test_bruxelles'

  # API pour calculs de primes
  namespace :api do
    # API BCE pour recherche d'entreprises
    post 'bce/search', to: 'bce#search'

    # API IA pour consultation
    post 'ai_consultations', to: 'ai_consultations#create'

    # API Aides Bruxelles pour entreprises
    get 'bruxelles_aides/categories', to: 'bruxelles_aides#categories'
    get 'bruxelles_aides/categories/:category_id', to: 'bruxelles_aides#category_details'

    # API Calculs Flandre
    post 'flandre/calculate_prime', to: 'flandre_calculations#calculate_prime'
    post 'flandre/calculate_all', to: 'flandre_calculations#calculate_all'

    namespace :v1 do
      namespace :wallonie do
        post 'check_eligibility', to: 'calculations#check_eligibility'
        post 'calculate_primes', to: 'calculations#calculate_primes'
        post 'get_category', to: 'calculations#get_category'
      end
    end

    # API BCE
    post '/bce/search', to: 'bce#search'
  end

  # Documents avec routes spéciales pour download et contexte
  resources :documents do
    member do
      get :download
      get :preview
      get :view
      get :debug
      get :ocr_view
    end
  end

  # Routes OCR
  post 'ocr/scan', to: 'ocr#scan'
  post 'ocr/scan_and_create_document', to: 'ocr#scan_and_create_document'

  # Documents officiels des primes (attestations, formulaires, etc.)
  resources :prime_document_templates, only: [:index, :show] do
    member do
      get :download
    end
  end

  # Routes pour téléchargement groupé de documents
  get 'primes/:id/download_documents', to: 'prime_document_templates#download_prime_documents', as: :download_documents_prime
  get 'simulations/:simulation_id/download_documents', to: 'prime_document_templates#download_simulation_documents', as: :download_documents_simulation

  resources :notifications, only: [:index, :show] do
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
  resources :properties do
    member do
      get :dashboard  # Dashboard spécifique pour un bien
      get :documents_dashboard  # Gestion des documents par bien
      get :documents_phases_dashboard  # Nouveau dashboard par phases métier
      get :formulaire_miroir  # Formulaire miroir pré-rempli
      post :submit_prime  # Soumission vers l'administration
      delete :destroy  # Route de suppression explicite

      # Nouvelle route pour sélecteur formulaires
      get :select_form, to: 'requests#select_form'
    end

    # Routes pour les requests liées à une propriété
    resources :requests, except: [:index, :show], shallow: true do
      member do
        patch :autosave  # Sauvegarde progressive AJAX
      end
    end
    # Documents liés à une propriété
    resources :documents, shallow: true
  end

  # Routes pour la validation technique
  resources :projects do
    # Documents liés à un chantier
    resources :documents, shallow: true

    # Routes pour les factures et leur analyse
    resources :factures, except: [:create] do
      member do
        patch :validate_facture
      end
    end

    # Routes spéciales pour l'analyse de factures
    get :factures_dashboard, to: 'factures#dashboard'
    post :upload_facture, to: 'factures#upload_facture'

    # Routes pour la validation technique
    member do
      get :technical_validation, to: 'technical_validations#show'
      post :validate_technical, to: 'technical_validations#validate'
      get :validation_report, to: 'technical_validations#report'
      post :revalidate, to: 'technical_validations#revalidate'
    end
  end

  # Routes pour les signatures entrepreneurs
  resources :requests do
    member do
      get :debug_export # Debug pour export data
    end
    resources :contractor_signatures, except: [:show] do
      member do
        post :resend
      end
      collection do
        post :send_batch
      end
    end
  end

  # Routes publiques pour les entrepreneurs (hors authentification)
  get '/contractor/:token', to: 'contractor_signatures#show', as: 'contractor_signature'
  post '/contractor/:token/sign', to: 'contractor_signatures#sign', as: 'sign_contractor'
  post '/contractor/:token/reject', to: 'contractor_signatures#reject', as: 'reject_contractor'

  # Routes pour les demandes de complément
  resources :request_progresses do
    resources :complement_requests do
      member do
        post :respond
        post :approve
        post :reject
        patch :extend_deadline
        post :send_reminder
      end
    end
  end

  # Routes admin pour les nouvelles fonctionnalités
  namespace :admin do
    # Gestion des utilisateurs pour les administrateurs
    resources :users do
      member do
        get :details        # AJAX endpoint pour charger les détails
        get :documents      # Voir tous les documents d'un utilisateur
        get :properties     # Voir toutes les propriétés d'un utilisateur
        get :projects       # Voir tous les projets d'un utilisateur
        post :impersonate   # Se connecter en tant qu'utilisateur (avec Pundit)
      end
    end

    resources :technical_validations, only: [:index, :show] do
      collection do
        post :bulk_validate
        get :analytics
        get :export_issues
      end
    end

    resources :contractor_signatures, only: [:index, :show] do
      collection do
        get :analytics
      end
    end

    resources :complement_requests, only: [:index, :show] do
      collection do
        get :analytics
      end
    end
  end

  # Routes pour vérifier le statut AJAX
  get '/contractor_signatures/:id/status', to: 'contractor_signatures#check_status'

  resources :requests do
    # Documents liés à une demande
    resources :documents, shallow: true

    # Suivis de demandes de primes
    resources :request_progresses, except: [:destroy], shallow: true

    member do
      patch :autosave  # Endpoint pour l'auto-save AJAX
    end
  end

  # Routes additionnelles pour les suivis de demandes
  resources :request_progresses, only: [:index, :show, :edit, :update, :destroy] do
    member do
      patch :upload_document  # Upload de documents de suivi
      patch :update_status_by_email  # Mise à jour par email de suivi
    end
  end

  resources :simulations do
    member do
      post :check_eligibility  # Étape 1: Vérification éligibilité (simple)
      post :check_eligibility_investment  # Étape 1a: Vérification éligibilité investissements (double)
      post :check_eligibility_renolution  # Étape 1b: Vérification éligibilité RENOLUTION (double)
      post :calculate_category  # Étape 2: Calcul de catégorie
      post :calculate_primes    # Étape 3: Calcul des primes
      post :calculate_prime     # Calcul d'une prime individuelle
      patch :update_prime_inputs # Sauvegarde des saisies utilisateur
      get :restore_prime_inputs # Restauration des saisies utilisateur

      # Decision Hub - Carrefour Conseil IA
      get :decision_hub  # Vue principale du carrefour conseil
      post :ai_consultation  # Endpoint pour les questions IA
    end
    # Documents liés à une simulation
    resources :documents, shallow: true
  end

  # Routes raccourcies pour le Decision Hub
  get '/conseil/:simulation_id', to: 'decision_hub#show', as: :decision_hub_short
  post '/conseil/:simulation_id/ia', to: 'decision_hub#ai_consultation', as: :decision_hub_ai

  # Decision Hub - Carrefour Conseil (page principale)
  resources :decision_hub, only: [:index] do
    collection do
      get :guide  # Guide d'utilisation
      get 'load_simulation/:simulation_id', to: 'decision_hub#load_simulation_data', as: 'load_simulation'
      post 'ai_consultation/:simulation_id', to: 'decision_hub#ai_consultation', as: 'ai_consultation'
      post :save_technical_preparation  # Sauvegarde des données techniques
    end
  end

  resources :users

  # config/routes.rb
  post "/calcul-categorie", to: "categories#calcul"
  get '/admin/dashboard', to: 'admin#dashboard'
  post '/admin/geocode_properties', to: 'admin#geocode_properties'
  post '/admin/generate_notifications', to: 'admin#generate_notifications'
  get    "/profil",           to: "users#profile", as: :profile
  get    "/profile",          to: redirect("/profil")  # Redirection EN -> FR
  get    "/profil/edition",   to: "users#edit",    as: :edit_profile
  patch  "/profil",           to: "users#update"

  get '/flandre', to: 'pages#flandre', as: :flandre
  get '/wallonie', to: 'pages#wallonie', as: :wallonie
  get '/wallonie/select-profile', to: 'pages#select_profile_wallonie'
  post '/wallonie/select-profile', to: 'pages#select_profile_wallonie', as: :select_profile_wallonie
  post '/wallonie/test-eligibility', to: 'pages#test_eligibility_wallonie', as: :test_eligibility_wallonie
  post '/wallonie/estimate-category', to: 'pages#estimate_category_wallonie', as: :estimate_category_wallonie
  get '/bruxelles', to: 'pages#bruxelles', as: :bruxelles
  post '/bruxelles/select-profile', to: 'pages#select_profile_bruxelles', as: :select_profile_bruxelles
  post '/bruxelles/test-eligibility', to: 'pages#test_eligibility_bruxelles', as: :test_eligibility_bruxelles
  post '/bruxelles/estimate-category', to: 'pages#estimate_category_bruxelles', as: :estimate_category_bruxelles

  # Nouveau simulateur : Aides aux entreprises Bruxelles
  get '/bruxelles-entreprises', to: 'pages#bruxelles_entreprises', as: :bruxelles_entreprises
  post '/bruxelles-entreprises/test-eligibility', to: 'pages#test_eligibility_bruxelles_entreprises', as: :test_eligibility_bruxelles_entreprises
  post '/bruxelles-entreprises/detailed-analysis', to: 'pages#detailed_business_eligibility_check', as: :detailed_business_eligibility_check

  # Pages d'information sur les aides aux entreprises (autres régions)
  get '/flandre-entreprises', to: 'pages#flandre_entreprises', as: :flandre_entreprises
  get '/wallonie-entreprises', to: 'pages#wallonie_entreprises', as: :wallonie_entreprises
  get '/mentions-legales', to: 'pages#legal', as: :legal
  get '/politique-de-confidentialite', to: 'pages#privacy', as: :privacy

  # Routes globales pour les gestionnaires (admin/modérateur)
  resources :technical_validations, only: [:index, :show]
  resources :contractor_signatures, only: [:index, :show]
  resources :complement_requests, only: [:index, :show]

  end # Fin du scope locale

  # Sitemap XML (hors scope locale pour éviter les conflits de langue)
  get '/sitemap.xml', to: 'sitemap#index', format: :xml

  # Robots.txt dynamique
  get '/robots.txt', to: 'robots#index', format: :text

  # Route pour les rapports de violation CSP (hors scope locale)
  post '/csp-violation-report-endpoint', to: 'security#csp_violation_report'

  # Route de redirection pour les URLs sans locale (mais pas pour Active Storage)
  # Route pour le favicon
  get '/favicon.ico', to: redirect('/icon.png')
  get '/favicon', to: redirect('/icon.png')

  get '/*path', to: redirect("/fr/%{path}"), constraints: lambda { |req|
    !req.path.starts_with?("/fr") &&
    !req.path.starts_with?("/nl") &&
    !req.path.starts_with?("/en") &&
    !req.path.starts_with?("/rails/active_storage") &&
    !req.path.starts_with?("/assets")
  }
end
