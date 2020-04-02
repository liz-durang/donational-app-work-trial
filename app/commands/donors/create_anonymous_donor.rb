module Donors
  class CreateAnonymousDonor < ApplicationCommand
    optional do
      boolean :is_uk_donor
    end

    def execute
      if is_uk_donor
        uk_donor = UkDonor.new
        uk_donor.save!(validate: false)
        uk_donor
      else
        Donor.create!
      end
    end
  end
end
