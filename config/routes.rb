Rails.application.routes.draw do
  # Acquisition
  root 'pages#index'
  %w(mission donate-with-confidence methodology faq api).each do |page_slug|
    get page_slug => 'pages#show', page: page_slug.underscore
  end

  resources :organizations, path: 'charities', only: :index

  # Activation
  mount ActionCable.server => '/cable'
  resource :onboarding, path: 'getting-started', only: :show
  resource :portfolio
  resource :allocations, only: %i[new edit create update]
  resource :accounts, only: %i[edit update]
  resource :payment_methods, only: %i[new create]
  resource :partners, only: %i[edit update]
  # Retention

  # Revenue
  resources :contributions

  # Referral
  get 'profiles/:username' => 'profiles#show', as: :profiles

  # Sessions and Authentication
  resource :sessions, only: %i[new destroy]
  get '/auth/oauth2/callback' => 'auth0#callback'
  get '/auth/failure' => 'auth0#failure'

  get '/:campaign_slug' => 'campaigns#show', as: :campaigns
  post '/:campaign_slug/contributions' => 'campaign_contributions#create', as: :campaign_contributions

end
