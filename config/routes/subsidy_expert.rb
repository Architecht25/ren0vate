  get  '/expert-subsides',          to: 'subsidy_expert#show',       as: :subsidy_expert
  post '/api/subsidy_bot/chat',      to: 'api/subsidy_bot#chat',      as: :api_subsidy_bot_chat
  post '/api/subsidy_bot/clear',     to: 'api/subsidy_bot#clear_history', as: :api_subsidy_bot_clear
