class Auth0Controller < ApplicationController
  def callback
    log_in! Donors::FindOrCreateDonorFromAuth.run!(request.env['omniauth.auth'])

    redirect_to portfolio_path
  end

  def failure
    # show a failure page or redirect to an error page
    @error_msg = request.params['message']
  end
end
