  resources :product_comparators, only: [] do
    collection do
      get  :index          # Sélecteur catégorie standalone
      get  :compare        # tableau instantané (sans IA)
      get  :recommendation # recommandation IA seule (lazy)
    end
  end
