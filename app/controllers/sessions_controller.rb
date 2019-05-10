class SessionsController < ApplicationController
  skip_forgery_protection only: [:destroy]

  def new
    if logged_in?
      redirect_to portfolio_path
    else
      redirect_to '/auth/auth0'
    end
  end

  def destroy
    log_out!
    redirect_to root_path
  end
end
