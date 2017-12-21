class Auth0Controller < ApplicationController
  def callback
    log_in! Donors::FindOrCreateDonorFromAuth.run!(request.env['omniauth.auth'])

    Analytics::TrackEvent.run(user_id: current_donor.id, event: 'Signed in')

    redirect_to portfolio_path
  end

  def failure
    raise request.params['message'].to_s
  end
end
