Rails.application.routes.draw do
  # Sessions and Authentication
  resource :sessions, only: %i[new destroy]
  get '/auth/oauth2/callback' => 'auth0#callback'
  get '/auth/failure' => 'auth0#failure'

  get 'dashboard' => 'dashboard#show'
  resource :portfolio
  resources :contributions, only: %i[index create]
  resource :payment_methods, path: 'payment-methods', only: %i[edit create]

  get 'profiles/:username' => 'profiles#show', as: :profiles

  root 'welcome#index'

  mount ActionCable.server => '/cable'
end
