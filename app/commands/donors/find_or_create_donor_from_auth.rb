module Donors
  class FindOrCreateDonorFromAuth
    def self.run!(auth)
      return nil if auth.blank?

      find_existing_donor_from(auth) || create_donor_and_portfolio_from!(auth)
    end

    def self.find_existing_donor_from(auth)
      Donor.find_by(email: auth.dig(:info, :email))
    end

    def self.create_donor_and_portfolio_from!(auth)
      Donor.create!(
        email: auth.dig(:info, :email),
        first_name: auth.dig(:info, :first_name) || auth.dig(:extra, :raw_info, :given_name),
        last_name: auth.dig(:info, :last_name) || auth.dig(:extra, :raw_info, :family_name)
      ).tap do |donor|
        Portfolios::CreateOrReplacePortfolio.run(donor: donor)
      end
    end
  end
end
