module Donations
  class DeleteDonationsForContribution < ApplicationCommand
    required do
      model :contribution
    end

    def execute
      Donation.where(contribution: contribution).destroy_all
      nil
    end
  end
end
