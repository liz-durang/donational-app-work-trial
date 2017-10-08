class ProfilesController < ApplicationController
  layout 'minimal'

  def show
    not_found unless donor

    @profile = OpenStruct.new(
      name: donor.first_name,
      video_url: "/path_to_video/#{donor.name.parameterize}"
    )
  end

  private

  def donor
    @donor ||= Donors::GetDonorByUsername.call(username: params[:username])
  end
end
