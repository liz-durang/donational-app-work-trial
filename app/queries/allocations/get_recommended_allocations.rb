module Allocations
  class GetRecommendedAllocations < ApplicationQuery
    def call(donor:)
      organizations = Organizations::GetOrganizationsThatMatchPriorities.call(donor: donor)
      active_subscription = Subscriptions::GetActiveSubscription.call(donor: donor)

      balanced_allocation_size, remainder = 100.divmod(organizations.size)

      organizations.map.with_index do |org, i|
        Allocation.new(
          subscription: active_subscription,
          organization_ein: org.ein,
          percentage: balanced_allocation_size + (i < remainder ? 1 : 0)
        )
      end
    end
  end
end
