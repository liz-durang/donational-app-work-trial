Rails.application.routes.draw do
  # Acquisition
  root 'welcome#index'

  # Activation
  resource :onboarding, path: 'getting-started', only: :show
  resource :portfolio

  # Retention

  # Revenue
  resource :allocations
  resources :contributions, only: %i[index new create]

  # Referral
  get 'profiles/:username' => 'profiles#show', as: :profiles

  # Sessions and Authentication
  resource :sessions, only: %i[new destroy]
  get '/auth/oauth2/callback' => 'auth0#callback'
  get '/auth/failure' => 'auth0#failure'

  mount ActionCable.server => '/cable'
end
