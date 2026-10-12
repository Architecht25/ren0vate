  # V2 — Lot 3 : simulation publique de primes (SubsidyCase), distincte de
  # resources :simulations (Simulation V1) définies dans config/routes/simulations.rb
  resources :subsidy_simulations, only: %i[new create show]
