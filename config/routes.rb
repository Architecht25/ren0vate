Rails.application.routes.draw do
  # Health-check — utilisé par UptimeRobot / load balancers (hors locale, sans auth)
  get "/up", to: "health#show", as: :health_check

  # PWA — manifest et service worker (hors locale scope pour URL propre)
  get "manifest" => "pwa#manifest", as: :pwa_manifest, defaults: { format: :json }
  get "service-worker" => "pwa#service_worker", as: :pwa_service_worker

  # Routes ActionMailbox pour la réception d'emails
  mount ActionMailbox::Engine => '/rails/action_mailbox'

  # Boîte aux lettres de dev — accessible sur /letter_opener
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

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
      sessions: 'users/sessions',
      registrations: 'users/registrations'
    }

    root "pages#home"

  # Onboarding tunnels (post-inscription, avant dashboard)
  scope '/onboarding', as: :onboarding do
    get  'profil',                     to: 'onboarding#profile_selection',              as: :profile_selection
    post 'profil',                     to: 'onboarding#set_profile',                    as: :set_profile

    get  'proprietaire/bien',          to: 'onboarding#proprietaire_bien',              as: :proprietaire_bien
    post 'proprietaire/bien',          to: 'onboarding#create_proprietaire_bien',       as: :create_proprietaire_bien

    get  'proprietaire/projet',        to: 'onboarding#proprietaire_projet',            as: :proprietaire_projet
    post 'proprietaire/projet',        to: 'onboarding#create_proprietaire_projet',     as: :create_proprietaire_projet

    get  'architecte/profil-pro',      to: 'onboarding#architecte_profil',              as: :architecte_profil
    post 'architecte/profil-pro',      to: 'onboarding#create_architecte_profil',       as: :create_architecte_profil

    get  'entrepreneur/invitation',    to: 'onboarding#entrepreneur_invitation',        as: :entrepreneur_invitation
    post 'entrepreneur/invitation',    to: 'onboarding#create_entrepreneur_invitation', as: :create_entrepreneur_invitation

    get  'intermediaire/structure',    to: 'onboarding#intermediaire_structure',        as: :intermediaire_structure
    post 'intermediaire/structure',    to: 'onboarding#create_intermediaire_structure', as: :create_intermediaire_structure
  end

  # Export comptable CSV (Entreprise+)
  get '/exports/comptable', to: 'exports#comptable', as: :export_comptable, defaults: { format: :csv }

  # Analytics multi-projets (Individual+)
  get '/analytics', to: 'analytics#index', as: :analytics

  # Pricing routes
  get '/pricing', to: 'pricing#index'
  get '/pricing/select', to: 'pricing#select'
  get '/pricing/summary/:tier', to: 'pricing#summary', as: 'pricing_summary'
  post '/pricing/checkout', to: 'pricing#checkout'
  post '/pricing/portal', to: 'pricing#portal', as: 'pricing_portal'
  get '/pricing/success', to: 'pricing#success'
  get '/pricing/cancel', to: 'pricing#cancel'

  # Webhook routes
  post '/webhooks/stripe', to: 'webhooks#stripe'

  # API routes
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

      # Routes API pour la sécurité
      get 'security/headers_check'
      get 'security/csp_violations'
      get 'security/security_overview'

      # API Calculs Flandre
      post 'flandre/calculate_prime', to: 'flandre_calculations#calculate_prime'
      post 'flandre/calculate_all', to: 'flandre_calculations#calculate_all'

      # NPS / feedback utilisateur
      post 'nps', to: 'nps#create'
    end

    # Dashboard routes
    get '/dashboard', to: 'dashboard#index', as: :dashboard
    get '/mes-projets-pro', to: 'projects#member_projects', as: :member_projects

    # Parrainage pro → client
    get  '/pro/inviter-client', to: 'pro_referrals#show',  as: :pro_referral
    post '/pro/inviter-client', to: 'pro_referrals#create', as: :create_pro_referral

  resources :primes
  resources :categories

  # Documents avec routes spéciales pour download et contexte
  resources :documents do
    member do
      get :download
      get :preview
      get :view
      get :debug
      get :ocr_view
    end
    collection do
      get :photos       # Galerie photos de suivi (sidebar section 6)
      get :download_zip # Télécharger toutes les photos d'un type en ZIP
    end
  end

  # Routes OCR
  post 'ocr/scan',                    to: 'ocr#scan'
  post 'ocr/scan_aer',                to: 'ocr#scan_aer',           as: :ocr_scan_aer
  post 'ocr/scan_rib',                to: 'ocr#scan_rib',           as: :ocr_scan_rib
  post 'ocr/scan_peb',                to: 'ocr#scan_peb',           as: :ocr_scan_peb
  post 'ocr/scan_devis',              to: 'ocr#scan_devis',             as: :ocr_scan_devis
  post 'ocr/analyser_devis',          to: 'ocr#analyser_devis',         as: :ocr_analyser_devis
  post 'ocr/optimiser_budget',        to: 'ocr#optimiser_budget',       as: :ocr_optimiser_budget
  post 'ocr/scan_bordereau_chassis',  to: 'ocr#scan_bordereau_chassis', as: :ocr_scan_bordereau_chassis
  post 'ocr/scan_label_energetique',  to: 'ocr#scan_label_energetique', as: :ocr_scan_label_energetique
  post 'ocr/scan_existing/:id',       to: 'ocr#scan_existing',      as: :ocr_scan_existing

  # Routes pour les templates de contrats
  resources :contract_templates, only: [:index, :show] do
    member do
      get :download
      get :preview
    end
  end
  post 'ocr/scan_and_create_document', to: 'ocr#scan_and_create_document'

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

  # Point d'entree global vers l'estimateur de devis (choix auto du bien)
  get 'quotes/start', to: 'quotes#start', as: :start_quotes
  get 'quotes/select_property', to: 'quotes#select_property', as: :select_property_quotes

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
      get  :mise_en_vente
      patch :activer_vente
      patch :desactiver_vente
      patch :marquer_vendu

      # Gestion locative
      get :gestion_locative

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

  # Routes pour la validation technique
  resources :projects do
    # Documents liés à un chantier
    resources :documents, shallow: true

    # Routes pour les factures et leur analyse
    resources :factures, except: [:create] do
      member do
        patch :validate_facture
        patch :validate_by_client
      end
    end

    # Routes spéciales pour l'analyse de factures
    get :factures_dashboard, to: 'factures#dashboard'
    post :upload_facture, to: 'factures#upload_facture'

    # Budget
    get  :edit_budget,   on: :member
    patch :update_budget, on: :member

    # Rapport PDF (Professional+)
    get :rapport_pdf, on: :member, defaults: { format: :pdf }

    # Professionnels
    get  :edit_professionals,   on: :member
    patch :update_professionals, on: :member

    # Planning / Gantt
    get :gantt, on: :member

    # Clôture de chantier : PEB après travaux & bilan final
    get  :fin_chantier,         on: :member
    post :scan_peb_apres,       on: :member
    post :scan_audit_energ,     on: :member
    patch :update_fin_chantier, on: :member

    # Réception de chantier (7.1)
    get  :reception_chantier,           on: :member
    post :scan_attestation_conformite,  on: :member
    post :upload_pv_externe,            on: :member

    # Garanties (7.2)
    get  :garanties,                    on: :member
    post :check_contrat,                on: :member

    # Carnet d'entretien / DIU (7.3)
    get  :carnet_entretien,             on: :member

    # ROI Calculator
    get  :roi_calculator,               on: :member

    # Analyse IA photos chantier
    post :analyze_photos,               on: :member
    get  :vision_status,                on: :member

    # IA #3 — Score Santé Projet
    get  :score_sante,                  on: :member

    # Collaboration — vue pro & invitations
    get  :pro_view,       to: 'pro_views#show',         on: :member
    post :invite,         to: 'pro_views#invite',        on: :member
    delete 'members/:member_id', to: 'pro_views#remove_member', on: :member, as: :remove_member

    # Suivi chantier — validation 3-parties (owner, architecte, entrepreneur)
    patch :validate_phase, on: :member

    # Upload facture côté entrepreneur (pro_view)
    post :upload_facture_pro,   to: 'pro_views#upload_facture_pro',   on: :member
    post :upload_photo_pro,     to: 'pro_views#upload_photo_pro',     on: :member

    # Upload document côté architecte (plan, métré, permis)
    post  :upload_document_pro, to: 'pro_views#upload_document_pro',  on: :member
    patch :update_permis_pro,   to: 'pro_views#update_permis_pro',    on: :member

    # Notification client depuis le dashboard intermédiaire (sans accès complet)
    post :notify_client, to: 'pro_views#notify_client', on: :member

    # Comparateur de devis reçus par email (OCR)
    get  :compare_devis, on: :member

    # États d'avancement structurés (bordereaux de paiement)
    resources :etats_avancement do
      member do
        post :soumettre
        post :approuver
        post :rejeter
        get  :pdf
      end
      collection do
        post :analyze_devis
        post :create_from_analysis
      end
    end

    # Réserves de réception (punch list)
    resources :reserves, only: %i[create update destroy]

    # Checklists d'inspection par phase
    resources :project_checklists, only: %i[create show destroy]

    # PV de réception numérique
    resource :pv_reception, only: %i[show create destroy] do
      member do
        post :send_signatures
        get  :print
      end
    end

    # PV de visite de chantier (multiples, rédigés par l'architecte)
    resources :pv_visites, only: %i[index show create update destroy] do
      member do
        post :send_links
        get  :print
      end
    end
  end

  # Items de checklists (toggle checked/unchecked) — shallow route
  resources :project_checklist_items, only: [:update]

  # Comparateur Produits & Matériaux (lié ou non à un projet)
  resources :product_comparators, only: [] do
    collection do
      get  :index          # Sélecteur catégorie standalone
      get  :compare        # tableau instantané (sans IA)
      get  :recommendation # recommandation IA seule (lazy)
    end
  end

  # PV de réception — liens de signature publics (sans authentification)
  get  'pv/:token', to: 'pv_signatures#show', as: :pv_signature
  post 'pv/:token', to: 'pv_signatures#sign', as: :sign_pv

  # PV de visite — liens de consultation publics (sans authentification, lecture seule)
  get 'visite/:token', to: 'pv_visite_links#show', as: :pv_visite_link

  # Acceptation invitations (lien email, sans authentification requise)
  get  'invitations/:token',            to: 'invitations#show',            as: :invitation
  post 'invitations/:token/accept',     to: 'invitations#accept',          as: :accept_invitation
  get  'invitations/:token/onboarding', to: 'invitations#new_onboarding',  as: :new_onboarding_invitation
  post 'invitations/:token/onboarding', to: 'invitations#create_onboarding'

  # Routes pour les demandes
  resources :requests

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
  # Support tickets — utilisateurs avec plan payant
  resources :support_tickets, only: [:index, :new, :create, :show] do
    member do
      post :reply
      patch :close
    end
  end

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
  end

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

  # Hub Estimer mes prêts
  get 'loans_hub',                    to: 'loans_hub#index',           as: :loans_hub
  get 'loans_hub/credit_classique',   to: 'loans_hub#credit_classique', as: :loans_hub_credit_classique
  get 'loans_hub/verbouwlening',      to: 'loans_hub#verbouwlening',    as: :loans_hub_verbouwlening
  get 'loans_hub/renopack',           to: 'loans_hub#renopack',         as: :loans_hub_renopack
  get 'loans_hub/ecoreno',            to: 'loans_hub#ecoreno',          as: :loans_hub_ecoreno

  # Hub Estimer mes primes
  get 'primes_hub', to: 'primes_hub#index', as: :primes_hub

  resources :simulations do
    member do
      post :check_eligibility  # Étape 1: Vérification éligibilité
      post :calculate_category  # Étape 2: Calcul de catégorie
      post :calculate_primes    # Étape 3: Calcul des primes
      post :calculate_prime     # Calcul d'une prime individuelle
      patch :update_prime_inputs # Sauvegarde des saisies utilisateur
      get :restore_prime_inputs # Restauration des saisies utilisateur
      patch :save_total         # Sauvegarde du total global calculé côté client

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
      get :expert  # Assistant IA Expert dédié
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
  get    "/profil/mes-donnees", to: "users#export_data", as: :export_user_data, defaults: { format: :json }

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

  # Blog public
  get '/blog',       to: 'blog#index', as: :blog_index
  get '/blog/:slug', to: 'blog#show',  as: :blog_show

  get '/mentions-legales', to: 'pages#legal', as: :legal
  get '/politique-de-confidentialite', to: 'pages#privacy', as: :privacy
  get '/conditions-generales', to: 'pages#terms', as: :terms
  get '/faq', to: 'pages#faq', as: :faq
  get '/aide', to: 'pages#aide', as: :aide
  get '/accord-de-traitement-des-donnees', to: 'pages#dpa', as: :dpa

  # 2FA admin — vérification OTP après connexion
  get  '/admin/2fa',        to: 'two_factor#show',   as: :admin_two_factor
  post '/admin/2fa/verify', to: 'two_factor#verify', as: :verify_admin_two_factor
  post '/admin/2fa/resend', to: 'two_factor#resend', as: :resend_admin_two_factor

  # Routes globales pour les gestionnaires (admin/modérateur)
  # complement_requests sont gérées uniquement via request_progresses (nested)

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
