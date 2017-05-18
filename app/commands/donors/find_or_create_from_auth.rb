module Donors
  class FindOrCreateFromAuth < Mutations::Command
    required do
      hash :info do
        required do
          string :email
        end
        optional do
          string :first_name
          string :last_name
        end
      end
    end
    optional do
      hash :extra
    end

    def execute
      find_donor_by_auth || create_donor_from_auth!
    end

    private

    def find_donor_by_auth
      Donor.find_by(email: info[:email])
    end

    def create_donor_from_auth!
      Donor.create!(
        email: info[:email],
        first_name: info[:first_name] || extra.dig(:raw_info, :given_name),
        last_name: info[:last_name] || extra.dig(:raw_info, :family_name)
      )
    end
  end
end
