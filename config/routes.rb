Rails.application.routes.draw do
  # Acquisition
  root 'pages#index'
  %w(mission donate-with-confidence methodology faq api).each do |page_slug|
    get page_slug => 'pages#show', page: page_slug.underscore, format: :html
  end

  resources :organizations, path: 'charities', only: :index

  mount ActionCable.server => '/cable'
  resource :onboarding, path: 'getting-started', only: :show

  # Activation
  resource :portfolio
  resource :allocations, only: %i[new edit create update]
  resource :accounts, only: %i[edit update]
  resource :payment_methods, only: :create
  resources :partners, only: %i[edit update] do
    resources :campaigns, only: %i[index new edit create update]
    get :account_connection, on: :collection
    resources :managed_portfolios, only: %i[index new edit create update] do
      collection do
        put 'order'
      end
    end
    resources :reports, module: :partners, only: :index do
      collection do
        get 'donors', format: :csv
        get 'donations', format: :csv
      end
    end
  end
  resources :searchable_organizations, only: :index
  # Retention

  # Revenue
  resources :contributions

  # Referral
  get 'profiles/:username' => 'profiles#show', as: :profiles, defaults: { format: :html }

  # Sessions and Authentication
  resource :sessions, only: %i[new destroy]
  get '/auth/oauth2/callback' => 'auth0#callback'
  get '/auth/failure' => 'auth0#failure'

  # Administration
  require "sidekiq/web"
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
  end if Rails.env.production?
  mount Sidekiq::Web, at: "/sidekiq"

  get '/:campaign_slug' => 'campaigns#show', as: :campaigns, defaults: { format: :html }
  post '/:campaign_slug/contributions' => 'campaign_contributions#create', as: :campaign_contributions
  get '/:campaign_slug/donation-box' => 'campaigns#donation_box', as: :campaigns_donation_box, defaults: { format: :html }

  # API
  namespace :api do
    namespace :v1, defaults: { format: :json } do
      resources :donors, only: [:create, :index, :show]
      resources :organizations, only: [:index, :show]
      resources :contributions, only: :create
      resources :portfolios, only: :index
      resources :hooks, only: [:index, :create]
    end
  end
end
