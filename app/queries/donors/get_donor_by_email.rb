module Donors
  class GetDonorByEmail  < ApplicationQuery
    def initialize(relation = Donor.all)
      @relation = relation
    end

    def call(email:)
      return nil if email.blank?

      @relation
        .where(deactivated_at: nil)
        .find_by(email: email)
    end
  end
end
