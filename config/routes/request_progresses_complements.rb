  resources :request_progresses do
    resources :complement_requests do
      member do
        post :respond
        post :approve
        post :reject
        patch :extend_deadline
        post :send_reminder
      end
    end
  end
