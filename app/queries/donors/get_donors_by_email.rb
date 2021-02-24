module Donors
  class GetDonorsByEmail  < ApplicationQuery
    def initialize(relation = Donor.all)
      @relation = relation
    end

    def call(email:)
      return nil if email.blank?

      @relation
        .where(email: email)
        .where(deactivated_at: nil)
    end
  end
end
