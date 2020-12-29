class PlaidAuthController < ApplicationController
  protect_from_forgery unless: -> { request.format.js? }

  def get_bank_token
    bank_account_token = Payments::GeneratePlaidBankToken.call(
      public_token: params[:public_token],
      account_id: params[:account_id],
    )

    if bank_account_token
      render json: { bank_account_token: bank_account_token }
    else
      render json: { status: 500 }
    end
  end
end
