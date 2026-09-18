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
  scope "(:locale)", locale: /fr|nl|en|es/ do
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
  draw :onboarding

  # Export comptable CSV (Entreprise+)
  get '/exports/comptable', to: 'exports#comptable', as: :export_comptable, defaults: { format: :csv }

  # Analytics multi-projets (Individual+)
  get '/analytics', to: 'analytics#index', as: :analytics

  # Pricing routes
  draw :pricing

  # Webhook routes
  post '/webhooks/stripe', to: 'webhooks#stripe'

  # API routes
  draw :api

    # Dashboard routes
    get '/dashboard', to: 'dashboard#index', as: :dashboard
    get '/mes-projets-pro', to: 'projects#member_projects', as: :member_projects

    # Parrainage pro → client
    get  '/pro/inviter-client', to: 'pro_referrals#show',  as: :pro_referral
    post '/pro/inviter-client', to: 'pro_referrals#create', as: :create_pro_referral

  resources :primes
  resources :categories

  # Documents avec routes spéciales pour download et contexte
  draw :documents

  # Routes OCR
  post 'ocr/scan',                    to: 'ocr#scan'
  post 'ocr/scan_aer',                to: 'ocr#scan_aer',           as: :ocr_scan_aer
  post 'ocr/scan_rib',                to: 'ocr#scan_rib',           as: :ocr_scan_rib
  post 'ocr/scan_peb',                to: 'ocr#scan_peb',           as: :ocr_scan_peb
  get  'ocr/scan_peb_statut',         to: 'ocr#scan_peb_statut',    as: :ocr_scan_peb_statut
  post 'ocr/scan_devis',              to: 'ocr#scan_devis',             as: :ocr_scan_devis
  get  'ocr/devis_analyse_contenu_statut', to: 'ocr#devis_analyse_contenu_statut', as: :ocr_devis_analyse_contenu_statut
  post 'ocr/analyser_devis',          to: 'ocr#analyser_devis',         as: :ocr_analyser_devis
  post 'ocr/optimiser_budget',        to: 'ocr#optimiser_budget',       as: :ocr_optimiser_budget
  post 'ocr/scan_bordereau_chassis',  to: 'ocr#scan_bordereau_chassis', as: :ocr_scan_bordereau_chassis
  post 'ocr/scan_label_energetique',  to: 'ocr#scan_label_energetique', as: :ocr_scan_label_energetique
  post 'ocr/scan_existing/:id',       to: 'ocr#scan_existing',      as: :ocr_scan_existing

  # Routes pour les templates de contrats
  draw :contract_templates
  post 'ocr/scan_and_create_document', to: 'ocr#scan_and_create_document'

  draw :notifications

  # Point d'entree global vers l'estimateur de devis (choix auto du bien)
  get 'quotes/start', to: 'quotes#start', as: :start_quotes
  get 'quotes/select_property', to: 'quotes#select_property', as: :select_property_quotes

  draw :property

  # Routes pour la validation technique
  draw :project

  # Items de checklists (toggle checked/unchecked) — shallow route
  resources :project_checklist_items, only: [:update]

  # Comparateur Produits & Matériaux (lié ou non à un projet)
  draw :product_comparators

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
  draw :request_progresses_complements

  # Routes admin pour les nouvelles fonctionnalités
  # Support tickets — utilisateurs avec plan payant
  draw :support_tickets

  draw :admin

  # API interne — réception des drafts depuis l'Agent Marketing (token Bearer)
  draw :api_v1

  draw :requests

  # Routes additionnelles pour les suivis de demandes
  draw :request_progresses

  # Hub Financer mes travaux — point d'entrée unique qui présente prêts et primes
  # côte à côte, plutôt que de forcer un choix de menu en amont (sidebar simplifiée).
  draw :financing_hubs

  draw :simulations

  # Routes raccourcies pour le Decision Hub
  draw :decision_hub

  resources :users

  # config/routes.rb
  post "/calcul-categorie", to: "categories#calcul"
  get '/admin/dashboard', to: 'admin#dashboard'
  post '/admin/geocode_properties', to: 'admin#geocode_properties'
  post '/admin/generate_notifications', to: 'admin#generate_notifications'
  draw :profile

  draw :region_landing_pages

  # Pages publiques (blog, légal)
  draw :public_pages

  # 2FA admin — vérification OTP après connexion
  draw :two_factor

  # Routes globales pour les gestionnaires (admin/modérateur)
  # complement_requests sont gérées uniquement via request_progresses (nested)

  # Expert Subsides — accessible pre-login (outil de conversion GTM)
  draw :subsidy_expert

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
