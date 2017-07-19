module Donors
  class FindDonorById
    def self.run!(id)
      return nil if id.blank?

      Donor.find_by(id: id)
    end
  end
end
