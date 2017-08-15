module Donations
  class GetUnpaidDonations < ApplicationQuery
    def initialize(relation = Donation.all)
      @relation = relation
    end

    def call(organization:)
      @relation.where(organization: organization, pay_out: nil)
    end
  end
end
