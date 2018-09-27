module Grants
  class ScheduleGrant < ApplicationCommand
    def execute
      unpaid_donations.each do |organization, donations|
        grant = Grant.create!(
          organization: organization,
          amount_cents: donations.sum(&:amount_cents)
        )

        donations.each do |donation|
          chain do
            Donations::MarkDonationAsProcessed.run(donation: donation, processed_by: grant)
          end
        end
      end

      nil
    end

    private

    def unpaid_donations
      Donations::GetUnpaidDonations.call
    end
  end
end
