module PayOuts
  class SchedulePayOut < Mutations::Command
    required do
      model :organization
      time :scheduled_at, after: Time.zone.now
    end

    def execute
      Donation.transaction do
        unpaid_donations = Donations::GetUnpaidDonations.call(organization: organization)

        pay_out = PayOut.create!(
          organization: organization,
          amount_cents: unpaid_donations.sum(:amount_cents),
          scheduled_at: scheduled_at
        )

        unpaid_donations.update_all(pay_out: pay_out)
      end

      nil
    end
  end
end
