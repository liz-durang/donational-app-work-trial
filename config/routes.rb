# frozen_string_literal: true

Rails.application.routes.draw do
  # Acquisition
  root 'pages#index'
  %w[mission donate-with-confidence methodology faq api].each do |page_slug|
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
        get 'organizations', format: :csv
        get 'gift_aid', format: :csv
      end
    end
    resources :donors, module: :partners, only: %i[index new edit create update]
    resources :payment_methods, module: :partners, only: %i[create]
    resources :refunds, module: :partners, only: %i[create]
    resources :donor_migrations, module: :partners, only: %i[create]
    resources :admins, module: :partners, only: %i[index new edit create update]
    resources :contributions, module: :partners
  end
  resources :searchable_organizations, only: :index
  # Retention

  # Revenue
  resources :contributions
  resources :grants, only: :show, param: :short_id

  # Referral
  get 'profiles/:username' => 'profiles#show', as: :profiles, defaults: { format: :html }

  # Sessions and Authentication
  resource :sessions, only: %i[new show destroy]
  get '/auth/oauth2/callback' => 'auth0#callback'
  get '/auth/failure' => 'auth0#failure'

  # Administration
  require 'sidekiq/web'
  if Rails.env.production?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV['SIDEKIQ_USERNAME'])) &
        ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV['SIDEKIQ_PASSWORD']))
    end
  end
  mount Sidekiq::Web, at: '/sidekiq'

  get '/:campaign_slug' => 'campaigns#show', as: :campaigns, defaults: { format: :html }
  post '/:campaign_slug/contributions' => 'campaign_contributions#create', as: :campaign_contributions
  get '/:campaign_slug/donation-box' => 'campaigns#donation_box', as: :campaigns_donation_box, defaults: { format: :html }

  # API
  namespace :api do
    namespace :v1, defaults: { format: :json } do
      resources :donors, only: %i[create index show]
      resources :organizations, only: %i[index show]
      resources :contributions, only: :create
      resources :portfolios, only: :index
      resources :hooks, only: %i[index create]
    end
  end
end
