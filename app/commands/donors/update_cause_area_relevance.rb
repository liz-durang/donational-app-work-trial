module Donors
  class UpdateCauseAreaRelevance
    def self.run!(donor, attributes)
      return nil if donor.blank?

      CauseAreaRelevance.find_or_initialize_by(donor: donor).update!(attributes)
    end
  end
end
