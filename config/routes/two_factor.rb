  get  '/admin/2fa',        to: 'two_factor#show',   as: :admin_two_factor
  post '/admin/2fa/verify', to: 'two_factor#verify', as: :verify_admin_two_factor
  post '/admin/2fa/resend', to: 'two_factor#resend', as: :resend_admin_two_factor
