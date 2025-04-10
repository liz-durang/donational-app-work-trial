module Portfolios
  class GetRecommendedAllocations < ApplicationQuery
    def call(donor:)
      organizations = Organizations::GetOrganizationsThatMatchPriorities.call(donor: donor)

      organizations_per_cause_area = { "focused" => 2, "mixed" => 3, "broad" => 4 }.fetch(donor.portfolio_diversity)
      organizations_per_cause_area += 1 unless organizations.distinct.count(:cause_area) > 1

      organizations = organizations.group_by(&:cause_area).map do |cause_area, orgs|
        orgs.sample(organizations_per_cause_area)
      end.flatten

      balanced_allocation_size, remainder = 100.divmod(organizations.size)

      organizations.map.with_index do |org, i|
        Allocation.new(
          organization_ein: org.ein,
          percentage: balanced_allocation_size + (i < remainder ? 1 : 0)
        )
      end
    rescue ZeroDivisionError
      []
    end
  end
end
