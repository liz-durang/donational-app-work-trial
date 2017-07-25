module Organizations
  class GetOrganizationsThatMatchPriorities < ApplicationQuery
    def initialize(relation = Organization.all)
      @relation = relation
    end

    def call(donor:)
      orgs = @relation

      orgs = orgs.where(local_impact: false) unless donor.include_local_organizations?
      orgs = orgs.where(global_impact: false) unless donor.include_global_organizations?
      orgs = orgs.where(immediate_impact: false) unless donor.include_immediate_impact_organizations?
      orgs = orgs.where(long_term_impact: false) unless donor.include_long_term_impact_organizations?
      orgs.to_a
    end
  end
end
