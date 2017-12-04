class SessionsController < ApplicationController
  def new
    redirect_to portfolio_path if logged_in?
  end

  def destroy
    log_out!
    redirect_to root_path
  end
end
