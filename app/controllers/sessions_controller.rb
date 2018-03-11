class SessionsController < ApplicationController
  def new
    @callback_url = auth_oauth2_callback_url
    @csrf_state = SecureRandom.hex(24)
    session['omniauth.state'] = @csrf_state

    redirect_to portfolio_path if logged_in?
  end

  def destroy
    log_out!
    redirect_to root_path
  end
end
