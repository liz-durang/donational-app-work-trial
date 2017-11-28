module Donors
  class UpdateDonor
    def self.run!(donor, attributes)
      return nil if donor.blank?

      donor.update!(attributes)
    end
  end
end
