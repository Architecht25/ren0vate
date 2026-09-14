  get '/blog',       to: 'blog#index', as: :blog_index
  get '/blog/:slug', to: 'blog#show',  as: :blog_show

  get '/mentions-legales', to: 'pages#legal', as: :legal
  get '/politique-de-confidentialite', to: 'pages#privacy', as: :privacy
  get '/conditions-generales', to: 'pages#terms', as: :terms
  get '/faq', to: 'pages#faq', as: :faq
  get '/aide', to: 'pages#aide', as: :aide
  get '/accord-de-traitement-des-donnees', to: 'pages#dpa', as: :dpa
