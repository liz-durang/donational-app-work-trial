class DonorsController < ApplicationController
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
      redirect_to edit_donors_path
    else
      flash[:error] = command.errors.message_list.join('<br/>').html_safe
      render :edit
    end
  end
end
