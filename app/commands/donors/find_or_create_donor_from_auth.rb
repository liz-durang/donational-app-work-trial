module Donors
  class FindOrCreateDonorFromAuth
    def self.run!(auth)
      return nil if auth.blank?

      Donor.find_by(email: auth.dig(:info, :email)) ||
        Donor.create!(
          email: auth.dig(:info, :email),
          first_name: auth.dig(:info, :first_name) || auth.dig(:extra, :raw_info, :given_name),
          last_name: auth.dig(:info, :last_name) || auth.dig(:extra, :raw_info, :family_name)
        )
    end
  end
end
