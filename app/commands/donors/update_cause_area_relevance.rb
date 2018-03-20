module Donors
  class UpdateCauseAreaRelevance < ApplicationCommand
    required do
      model :donor
      array :causes_that_matter
    end

    def execute
      CauseAreaRelevance.find_or_initialize_by(donor: donor).update!(scored_cause_areas)
    end

    private

    def scored_cause_areas
      all_recommendable_causes.map do |cause_area|
        [cause_area, cause_area.in?(causes_that_matter) ? 7 : 0]
      end.to_h
    end

    def all_recommendable_causes
      Organization::recommendable_cause_areas.map(&:to_sym)
    end
  end
end
