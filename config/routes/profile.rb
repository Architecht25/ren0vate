  get    "/profil",           to: "users#profile", as: :profile
  get    "/profile",          to: redirect("/profil")  # Redirection EN -> FR
  get    "/profil/edition",   to: "users#edit",    as: :edit_profile
  patch  "/profil",           to: "users#update"
  get    "/profil/mes-donnees", to: "users#export_data", as: :export_user_data, defaults: { format: :json }
