Rails.application.routes.draw do
  devise_for :authors, controllers: {
    sessions: 'api/v1/authors/sessions',
    registrations: 'api/v1/authors/registrations',
    confirmations: 'api/v1/authors/confirmations',
    passwords: 'api/v1/authors/passwords',
    omniauth_callbacks: 'api/v1/authors/omniauth_callbacks'
  }, path: 'api/v1/authors', defaults: { format: :json }

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
      devise_scope :author do
        post 'authors/google_oauth2', to: 'authors/sessions#google_oauth2'
      end

      namespace :authors do
        get 'me', to: 'profiles#show'
      end

      resources :books do
        collection do
          get :my_books
          get :storefront
        end
        member do
          get :storefront
          get :content
        end
      end

      # Admin account management
      resources :admins, only: %i[index show create]

      namespace :admin do
        resources :books do
          member do
            patch :approve
            patch :reject
          end
        end

        resources :authors, only: %i[index show]

        resources :author_revenues, only: %i[index show] do
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

        get 'revenue_dashboard', to: 'dashboard#revenue'
      end

      # Author account management
      namespace :authors do
        resource :profile, only: %i[show update create]
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

      namespace :author do
        resources :earnings, only: [] do
          collection do
            get :summary
            get :breakdowns
            get :recent_sales
            get :approved_payments
          end
        end

        resources :payment_histories, only: %i[index show]

        resource :banking_details, only: %i[show update] do
          post :verify
          get :banks
        end
      end

      namespace :readers do
        resource :profile, only: %i[show update create]
      end

      namespace :reader do
        resources :current_reads, only: [:index] do
          patch ':book_id', to: 'current_reads#update', on: :collection
        end

        resources :finished_books, only: [:index]
      end

      resources :purchases, only: %i[create index] do
        collection do
          post :verify
          post :refresh_reading_token
          get :check_status
        end
      end

      resources :books do
        member do
          get :content # GET /api/v1/books/:id/content
        end
      end

      resources :reviews, only: %i[create update destroy] do
        collection do
          # These are missing actions in the reviews controller
          get :my_reviews # GET /api/v1/reviews/my_reviews
          get :recent_reviews # GET /api/v1/reviews/recent_reviews
          get :top_reviews # GET /api/v1/reviews/top_reviews
        end
      end

      resources :likes, only: %i[index create destroy]

      resources :reading_tokens, only: [:create]

      resource :direct_uploads, only: [:create]
    end
  end

  # Additional routes
  devise_scope :author do
    post '/api/v1/authors/confirmation/confirm', to: 'api/v1/authors/confirmations#confirm'
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
  root 'api/v1/status#index'
end
