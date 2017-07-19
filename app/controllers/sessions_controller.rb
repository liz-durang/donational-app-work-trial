class SessionsController < ApplicationController
  # GET /sessions/new
  def new
    redirect_to dashboard_path if logged_in?
  end

  # DELETE /sessions/1
  # DELETE /sessions/1.json
  def destroy
    log_out!
    redirect_to dashboard_path
  end
end
