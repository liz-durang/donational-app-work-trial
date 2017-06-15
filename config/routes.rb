Rails.application.routes.draw do
  resource :sessions, only: %i[new destroy]
  get '/auth/oauth2/callback' => 'auth0#callback'
  get '/auth/failure' => 'auth0#failure'

  get 'dashboard' => 'dashboard#show'

  mount ActionCable.server => '/cable'
end
