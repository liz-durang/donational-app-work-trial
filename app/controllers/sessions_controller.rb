class SessionsController < ApplicationController
  skip_forgery_protection only: [:destroy]

  def new
    log_out! if logged_in?
    redirect_to '/auth/auth0'
  end

  def show; end

  def destroy
    log_out!
    redirect_to root_path
  end
end
