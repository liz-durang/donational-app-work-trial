Rails.application.routes.draw do
  # Acquisition
  root 'welcome#index'

  # Activation
  resource :onboarding, only: :show
  resource :portfolio
  # Retention

  # Revenue
  resources :contributions, only: %i[index create]
  resource :payment_methods, path: 'payment-methods', only: %i[edit create]

  # Referral
  get 'profiles/:username' => 'profiles#show', as: :profiles

  # Sessions and Authentication
  resource :sessions, only: %i[new destroy]
  get '/auth/oauth2/callback' => 'auth0#callback'
  get '/auth/failure' => 'auth0#failure'

  mount ActionCable.server => '/cable'
end
