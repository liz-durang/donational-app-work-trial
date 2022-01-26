module Donations
  class DeleteUngrantedDonationsForContribution < ApplicationCommand
    required do
      model :contribution
    end

    def execute
      Donation.where(contribution: contribution, grant: nil).destroy_all
      nil
    end
  end
end
