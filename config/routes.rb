Rails.application.routes.draw do
 
  devise_for :authors, controllers: {
  sessions: 'api/v1/authors/sessions',
  registrations: 'api/v1/authors/registrations',
  confirmations: 'api/v1/authors/confirmations',
  passwords: 'api/v1/authors/passwords'
  }, defaults: { format: :json },
     path: 'api/v1/authors'

  devise_for :admins, controllers: {
  sessions: 'api/v1/admins/sessions'
  }, skip: [:registrations],
     path: 'api/v1/admins'
  
  # API Routes
  namespace :api do
    namespace :v1 do
      resources :books do
        collection do
          get :my_books
        end
      end
      resources :admins
     
      namespace :authors do
        resource :profile, only: [:show, :update, :create]
      end

      resources :purchases do
        collection do
          post :verify 
        end 
      end 
      
      resource :direct_uploads, only: [:create]
    end
  end


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
