Rails.application.routes.draw do
  # Sessions and Authentication
  resource :sessions, only: %i[new destroy]
  get '/auth/oauth2/callback' => 'auth0#callback'
  get '/auth/failure' => 'auth0#failure'

  get 'dashboard' => 'dashboard#show'
  resource :subscription

  get 'profiles/:username' => 'profiles#show'

  root 'welcome#index'

  mount ActionCable.server => '/cable'
end
