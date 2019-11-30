module Donations
  class CreateDonationsFromContributionIntoPortfolio < ApplicationCommand
    required do
      model :contribution
      integer :donation_amount_cents, min: 100
    end

    def execute
      create_donation_for_each_organization_in_the_portfolio!
      create_donation_for_operating_cost!

      nil
    end

    private

    def operating_costs_donation_amount_cents
      (donation_amount_cents * contribution.partner_contribution_percentage / 100.0).floor
    end

    def non_operating_costs_donation_amount_cents
      @non_operating_costs_donation_amount_cents ||= donation_amount_cents - operating_costs_donation_amount_cents 
    end

    def create_donation_for_operating_cost!
      return unless operating_costs_donation_amount_cents > 0
     
      Donation.create!(
        allocation: nil,
        contribution: contribution,
        portfolio: contribution.portfolio,
        organization: contribution.partner.operating_costs_organization,
        amount_cents: operating_costs_donation_amount_cents
      )
    end

    def create_donation_for_each_organization_in_the_portfolio!
      Portfolios::GetActiveAllocations.call(portfolio: contribution.portfolio).each do |a|
        amount_cents = (non_operating_costs_donation_amount_cents * a.percentage / 100.0).floor
        Donation.create!(
          allocation: a,
          contribution: contribution,
          portfolio: contribution.portfolio,
          organization: a.organization,
          amount_cents: amount_cents
        )
      end
    end
  end
end
