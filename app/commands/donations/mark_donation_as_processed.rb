module Donations
  class MarkDonationAsProcessed < ApplicationCommand
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
