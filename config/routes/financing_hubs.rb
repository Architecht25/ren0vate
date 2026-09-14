  get 'financement', to: 'financement#index', as: :financement

  # Hub Estimer mes prêts
  get 'loans_hub',                    to: 'loans_hub#index',           as: :loans_hub
  get 'loans_hub/credit_classique',   to: 'loans_hub#credit_classique', as: :loans_hub_credit_classique
  get 'loans_hub/verbouwlening',      to: 'loans_hub#verbouwlening',    as: :loans_hub_verbouwlening
  get 'loans_hub/renopack',           to: 'loans_hub#renopack',         as: :loans_hub_renopack
  get 'loans_hub/ecoreno',            to: 'loans_hub#ecoreno',          as: :loans_hub_ecoreno

  # Hub Estimer mes primes
  get 'primes_hub', to: 'primes_hub#index', as: :primes_hub
