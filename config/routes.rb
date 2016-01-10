Rails.application.routes.draw do


namespace :api do
  namespace :v1 do

    resources :users,     only: [:index, :show, :create, :update, :destroy] do
      get :me, on: :collection
    end
    resources :projects,  only: [:index, :show, :create, :update, :destroy] do
      resources :tickets,   only: [:index, :show, :create, :update, :destroy]
    end
    
  end
end

end
