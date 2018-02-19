class WelcomeController < ApplicationController
  def index
  end

  def show
    not_found unless params[:page] == 'faq'

    render 'faq'
  end
end
