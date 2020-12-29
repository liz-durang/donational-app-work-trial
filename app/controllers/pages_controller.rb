class PagesController < ApplicationController
  def index
    @view_model = view_model
  end

  def show
    @view_model = view_model
    render params[:page]
  end

  private

  def view_model
    OpenStruct.new(
      currency_code: current_currency.iso_code
    )
  end
end
