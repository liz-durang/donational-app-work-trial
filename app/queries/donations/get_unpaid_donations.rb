module Donations
  class GetUnpaidDonations < ApplicationQuery
    def initialize(relation = Donation.all)
      @relation = relation
    end

    def call
      @relation
        .where(grant: nil)
        .group_by { |donation| donation.organization }
    end
  end
end
