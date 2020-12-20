class Auth0Controller < ApplicationController
  def callback

    if matching_donor
      log_in! matching_donor
      Analytics::TrackEvent.run(user_id: current_donor.id, event: 'Signed in')
      redirect_to portfolio_path
    else
      flash[:error] = "Could not find an account that matches this email address"
      redirect_to sessions_path
    end
  end

  def matching_donor
    @matching_donor ||= Donors::FindOrCreateDonorFromAuth.run!(request.env['omniauth.auth'])
  end

  def failure
    raise request.params['message'].to_s
  end
end
