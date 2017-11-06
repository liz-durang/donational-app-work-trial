module Donations
  class MarkDonationAsProcessed < Mutations::Command
    required do
      model :donation
      model :processed_by, class: Grant
    end

    def execute
      donation.update(grant: processed_by)
      nil
    end
  end
end
