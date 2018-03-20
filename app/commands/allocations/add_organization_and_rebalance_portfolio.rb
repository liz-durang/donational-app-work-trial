module Allocations
  class AddOrganizationAndRebalancePortfolio < ApplicationCommand
    required do
      model :portfolio
      model :organization
    end

    def execute
      new_allocation = {
        organization_ein: organization.ein,
        percentage: 100 - existing_allocations_with_room_for_new_org.sum { |a| a[:percentage] }
      }

      chain UpdateAllocations.run(
        portfolio: portfolio,
        allocations: existing_allocations_with_room_for_new_org + [new_allocation]
      )

      nil
    end

    private

    def existing_allocations
      @existing_allocations ||= Allocations::GetActiveAllocations.call(portfolio: portfolio)
    end

    def scaled_percentage_of_existing_organizations
      1 - 1.0 / (existing_allocations.count + 1)
    end

    def existing_allocations_with_room_for_new_org
      @existing_allocations_with_room_for_new_org ||= existing_allocations.map do |allocation|
        scaled_percentage = allocation[:percentage] * scaled_percentage_of_existing_organizations

        { organization_ein: allocation[:organization_ein], percentage: scaled_percentage.round }
      end
    end
  end
end
