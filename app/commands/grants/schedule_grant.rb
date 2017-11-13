module Grants
  class ScheduleGrant < Mutations::Command
    required do
      model :organization
      time :scheduled_at, after: Time.zone.now
    end

    def execute
      Donation.transaction do
        unpaid_donations = Donations::GetUnpaidDonations.call(organization: organization)

        grant = Grant.create!(
          organization: organization,
          amount_cents: unpaid_donations.sum(:amount_cents),
          scheduled_at: scheduled_at
        )

        unpaid_donations.each do |donation|
          Donations::MarkDonationAsProcessed.run!(donation: donation, processed_by: grant)
        end
      end

      nil
    end
  end
end
