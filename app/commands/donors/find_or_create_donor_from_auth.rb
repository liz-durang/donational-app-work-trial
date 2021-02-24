module Donors
  class FindOrCreateDonorFromAuth
    def self.run!(auth)
      return nil if auth.blank?

      Donor
        .where(deactivated_at: nil)
        .find_by(email: auth.dig(:info, :email))
    end
  end
end
