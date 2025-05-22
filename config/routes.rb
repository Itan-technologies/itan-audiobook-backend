Rails.application.routes.draw do
  devise_for :authors, controllers: {
    sessions: 'api/v1/authors/sessions',
    registrations: 'api/v1/authors/registrations',
    confirmations: 'api/v1/authors/confirmations',
    passwords: 'api/v1/authors/passwords',
    omniauth_callbacks: 'api/v1/authors/omniauth_callbacks'
  }, defaults: { format: :json },
     path: 'api/v1/authors'

  devise_for :admins, controllers: {
    sessions: 'api/v1/admins/sessions'
  }, skip: [:registrations],
     path: 'api/v1/admins'
  
  devise_for :readers, controllers: {
    sessions: 'api/v1/readers/sessions',
    registrations: 'api/v1/readers/registrations'
  }, defaults: { format: :json },
     path: 'api/v1/readers'
     
  # API Routes
  namespace :api do
    namespace :v1 do
      resources :books do
        collection do
          get :my_books          
        end
      end

      # Admin account management
      resources :admins, only: [:index, :show, :create, :destroy]

      # Admin functionality namespace
      namespace :admin do
        resources :books do
          member do
            patch :approve
            patch :reject
          end
        end
        resources :authors, only: [:index, :show]       
      end

      # Author account management    
      namespace :authors do
        resource :profile, only: [:show, :update, :create]
        post 'verify', to: 'verifications#verify'
        post 'resend_code', to: 'verifications#resend'
        
        resource :two_factor, only: [] do
          get :status
          post :enable_email
          post :setup_sms
          post :verify_sms
          delete :disable
        end
      end

      namespace :readers do
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

  # Additional routes
  devise_scope :author do
    post '/api/v1/authors/confirmation/confirm', to: 'api/v1/authors/confirmations#confirm'
  end
  
  get "up" => "rails/health#show", as: :rails_health_check
  root "api/v1/status#index"
end
