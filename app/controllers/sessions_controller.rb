class SessionsController < ApplicationController
  # GET /sessions/new
  def new
  end

  # DELETE /sessions/1
  # DELETE /sessions/1.json
  def destroy
    reset_session
    redirect_to dashboard_path
  end
end
