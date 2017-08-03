module Donors
  class CreateAnonymousDonor
    def self.run!
      Donor.create!
    end
  end
end
