module Donations
  class MarkDonationAsProcessed < Mutations::Command
    required do
      model :donation
      model :processed_by, class: PayOut
    end

    def execute
      donation.update(pay_out: processed_by)
      nil
    end
  end
end
