module Donations
  class GetUnpaidDonations
    class << self
      delegate :call, to: :new
    end

    def initialize(relation = Donation.all)
      @relation = relation
    end

    def call(organization:)
      @relation.where(organization: organization, pay_out: nil)
    end
  end
end
