Rails.application.routes.draw do
 
  devise_for :authors, controllers: {
  sessions: 'authors/sessions',
  registrations: 'authors/registrations',
  confirmations: 'authors/confirmations'
  }, defaults: { format: :json }

  devise_for :admins, controllers: {
  sessions: 'admins/sessions'
  }, skip: [:registrations]
  
  # API Routes
  namespace :api do
    namespace :v1 do
      resources :books
      
      # Additional book routes (if needed)
      # get 'books/featured', to: 'books#featured'
      # get 'books/search', to: 'books#search'
    end
  end

  post '/direct_uploads', to: 'direct_uploads#create'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
