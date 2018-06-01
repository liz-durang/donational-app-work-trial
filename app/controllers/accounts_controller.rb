class AccountsController < ApplicationController
  include Secured

  def update
    command = Donors::UpdateDonor.run(
      donor: current_donor,
      first_name: params[:donor][:first_name],
      last_name: params[:donor][:last_name],
      email: params[:donor][:email]
    )

    if command.success?
      flash[:success] = "Thanks, we've updated your account"
      redirect_to edit_accounts_path
    else
      flash[:error] = command.errors.message_list.join('. ')
      redirect_to edit_accounts_path
    end
  end

  def edit
    @view_model = OpenStruct.new(
      donor: current_donor,
      accounts_path: accounts_path
    )
  end
end
