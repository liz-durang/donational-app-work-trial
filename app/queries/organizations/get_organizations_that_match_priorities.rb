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
      relevance_scores.select { |_, score| score.to_i >= 4 }.keys
    end

    def cause_areas
      %w[
        global_health
        poverty_and_income_inequality
        climate_and_environment
        animal_welfare
        hunger_nutrition_and_safe_water
        women_and_girls
        immigration_and_refugees
        education
        economic_development
      ]
    end
  end
end
