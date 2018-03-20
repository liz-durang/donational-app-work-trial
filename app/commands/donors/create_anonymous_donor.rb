module Donors
  class CreateAnonymousDonor < ApplicationCommand
    def execute
      Donor.create!
    end
  end
end
