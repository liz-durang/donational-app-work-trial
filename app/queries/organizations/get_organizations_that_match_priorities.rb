module Organizations
  class GetOrganizationsThatMatchPriorities < ApplicationQuery
    def initialize(relation = Organization.all)
      @relation = relation
    end

    def call(donor:)
      @relation.where(cause_area: important_cause_areas_for(donor))
    end

    def important_cause_areas_for(donor)
      relevance_scores = CauseAreaRelevance.where(donor: donor).first.attributes.slice(*cause_areas)
      relevance_scores.select { |_, score| score.to_i >= 5 }.keys
    end

    def cause_areas
      Organization::CAUSE_AREAS
    end
  end
end
