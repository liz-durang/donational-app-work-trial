module Organizations
  class GetOrganizationsThatMatchPriorities < ApplicationQuery
    def initialize(relation = Organization.all)
      @relation = relation
    end

    def call(donor:)
      @relation.where(
        cause_area: important_cause_areas_for(donor),
        deactivated_at: nil,
        suggested_by_donor: nil
      )
    end

    def important_cause_areas_for(donor)
      relevance_scores = CauseAreaRelevance.where(donor: donor).first.attributes.slice(*cause_areas)
      top_score = relevance_scores.values.compact.max
      relevance_scores.select { |_, score| score.to_i >= top_score - 1 }.keys
    end

    def cause_areas
      Organization::CAUSE_AREAS
    end
  end
end
