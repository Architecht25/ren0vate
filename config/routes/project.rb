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
    get :edit_professionals,   on: :member
    patch :update_professionals, on: :member

    # Planning / Gantt
    get :gantt, on: :member

    # Clôture de chantier : PEB après travaux & bilan final
    get  :fin_chantier,         on: :member
    post :scan_peb_apres,       on: :member
    post :scan_audit_energ,     on: :member
    get  :audit_energ_statut,   on: :member
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

    # Carnet de bord — notes libres
    resources :project_notes, only: %i[create destroy]

    # Suivi du dossier de prêt bonifié wallon (régime "reduction_pret")
    resource :pret_wallonie_dossier, only: %i[show create update]

    # Plan de financement — fonds propres, emprunts, primes vs coût total du chantier
    resources :financing_sources, except: %i[index show]

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
