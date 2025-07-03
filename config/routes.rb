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
          get :categories      
        end
      end

      # Admin account management
      resources :admins, only: [:index, :show, :create]

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

      namespace :admin do
        resources :author_revenues, only: [:index, :show] do
          collection do
            post :process_payments
            post :transfer_funds
            get :processed_batches
            get :transferred_authors
          end
        end

        resources :analytics, only: [] do
            collection do              
              get :financial_summary
            end
        end
        
        # Optional: analytics dashboard routes
        get 'revenue_dashboard', to: 'dashboard#revenue'
      end

      # Author account management    
      namespace :authors do
        resource :profile, only: [:show, :update, :create]
        post 'verify', to: 'verifications#verify'
        post 'resend_verification', to: 'verifications#resend_verification'
        
        resource :two_factor, only: [] do
          get :status
          post :enable_email
          post :setup_sms
          post :verify_sms
          delete :disable
        end
      end

      # Author-facing routes
      namespace :author do
        resources :earnings, only: [] do
          collection do
            get :summary
            get :breakdowns
            get :recent_sales
            get :approved_payments
          end
        end
        
        # Individual payment historys
        resources :payment_histories, only: [:index, :show]
      end
        
      namespace :author do
        resource :banking_details, only: [:show, :update] do
          post :verify
          get :banks
        end
      end

      namespace :readers do
        resource :profile, only: [:show, :update, :create]
      end

      resources :purchases, only: [:create, :index] do
        collection do
          post :verify 
          post :refresh_reading_token
          get :check_status
        end
      end

      resources :books do
        member do
          get :content  # Creates GET /api/v1/books/:id/content
        end
      end
    
      # ✅ READER - Complete routes for DRM protected reading
      # resources :reader, only: [:show] do
      #   member do
      #     get :metadata      # GET /api/v1/reader/:id/metadata?token=...
      #     get :page         # GET /api/v1/reader/:id/page?page=1&token=...
      #     # post :refresh_reading_token
      #     # get :audio_chunk  # GET /api/v1/reader/:id/audio_chunk?start=120&token=...
      #   end
      # end
      
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
