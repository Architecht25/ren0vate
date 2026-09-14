  # Pricing routes
  get '/pricing', to: 'pricing#index'
  get '/pricing/select', to: 'pricing#select'
  get '/pricing/summary/:tier', to: 'pricing#summary', as: 'pricing_summary'
  post '/pricing/checkout', to: 'pricing#checkout'
  post '/pricing/portal', to: 'pricing#portal', as: 'pricing_portal'
  get '/pricing/success', to: 'pricing#success'
  get '/pricing/cancel', to: 'pricing#cancel'
