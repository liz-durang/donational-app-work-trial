module Donors
  class FindDonorFromAuth
    def self.run!(auth)
      return nil if auth.blank?

      Donor
        .where(deactivated_at: nil)
        .where('LOWER(email) = ?', auth.dig(:info, :email).downcase)
        .first
    end
  end
end
