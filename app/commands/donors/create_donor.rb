module Donors
  class CreateDonor
    def self.run!
      Donor.create!
    end
  end
end
