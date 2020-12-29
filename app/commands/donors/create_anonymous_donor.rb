module Donors
  class CreateAnonymousDonor < ApplicationCommand
    optional do
      string :donor_id
    end

    def execute
      Donor.create!(id: donor_id)
    end
  end
end
