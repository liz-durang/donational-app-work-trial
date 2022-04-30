class SessionsController < ApplicationController
  skip_forgery_protection only: [:destroy]

  def new; end

  def destroy
    log_out!
    redirect_to root_path
  end
end
