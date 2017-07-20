class SessionsController < ApplicationController
  def new
    redirect_to dashboard_path if logged_in?
  end

  def destroy
    log_out!
    redirect_to dashboard_path
  end
end
