module Portfolios
  class AddOrganizationsAndRebalancePortfolio < ApplicationCommand
    required do
      model :portfolio
      array :organization_eins
    end

    def execute
      new_allocations = adjust_to_ensure_100_percent(
        scaled_existing_allocations + allocations_for_new_organizations
      )

      if new_allocations.any? { |a| a[:percentage] < 1 }
        add_error(
          :portfolio,
          :balancing_would_remove_organization,
          'Balancing would remove organization from portfolio'
        )
        return nil
      end

      chain do
        UpdateAllocations.run(portfolio: portfolio, allocations: new_allocations)
      end

      nil
    end

    private

    def allocations_for_new_organizations
      organization_eins.map do |ein|
        { organization_ein: ein, percentage: target_percentage }
      end
    end

    def existing_allocations
      @existing_allocations ||= Portfolios::GetActiveAllocations.call(portfolio: portfolio)
    end

    # The percentage allocated to each new organization if the portfolio was evenly balanced
    def target_percentage
      100 / future_portfolio_size
    end

    def future_portfolio_size
      organization_eins.count + existing_allocations.count
    end

    def existing_organization_scaling_factor
      existing_allocations.size.to_f / future_portfolio_size
    end

    # scale each of the existing allocations to based on the amount of room needed for the new orgs
    def scaled_existing_allocations
      existing_allocations.map do |allocation|
        {
          organization_ein: allocation[:organization_ein],
          percentage: (allocation[:percentage] * existing_organization_scaling_factor).round
        }
      end
    end

    def adjust_to_ensure_100_percent(allocations)
      # due to scaling and rounding, we might not add to 100%
      amount_to_adjust = 100 - allocations.sum { |a| a[:percentage] }

      return allocations if amount_to_adjust == 0

      # we create an array like [1, 1, 1, 1, 1, 1] or [-1, -1, -1, -1, -1, -1]
      adjustments = if amount_to_adjust > 0
                      [1] * amount_to_adjust
                    else
                      [-1] * amount_to_adjust.abs
                    end

      # split the array to match the size of the existing allocations
      # [-1, -1, -1, -1]
      # [-1, -1]
      adjustments = adjustments.in_groups_of(allocations.size, 0)

      # sum to find how much to remove from each org
      # [-2, -2, -1, -1]
      adjustments = adjustments.transpose.map(&:sum)

      allocations.zip(adjustments).map do |allocation, adjustment|
        {
          organization_ein: allocation[:organization_ein],
          percentage: allocation[:percentage] + adjustment
        }
      end
    end
  end
end
