require 'rails_helper'

RSpec.describe Allocations::AddOrganizationAndRebalancePortfolio do
  let(:portfolio) { create(:portfolio) }
  let!(:new_organization) { create(:organization, ein: 'org_to_be_added') }

  context 'when there is no organization supplied' do
    let(:no_organization) { nil }

    it 'does not run, and includes a nil allocations error' do
      command = Allocations::AddOrganizationAndRebalancePortfolio.run(
        portfolio: portfolio,
        organization: no_organization
      )

      expect(command).not_to be_success
      errors = command.errors.symbolic
      expect(errors).to include(organization: :nils)
    end
  end

  context 'when there are no existing allocations in the portfolio' do
    before { create_existing_allocations_with_percentages([]) }

    it 'adds the organization to the portfolio with a 100% allocation' do
      expect(Allocations::UpdateAllocations)
        .to receive(:run)
        .with(portfolio: portfolio, allocations: [organization_ein: 'org_to_be_added', percentage: 100])
        .and_return(double(success?: true))

      Allocations::AddOrganizationAndRebalancePortfolio.run(portfolio: portfolio, organization: new_organization)
    end
  end

  context 'When there is a single existing allocation' do
    it 'evenly splits the portfolio [50%, 50%]' do
      create_existing_allocations_with_percentages([100])
      expect_percentages_to_update_to([50, 50])

      Allocations::AddOrganizationAndRebalancePortfolio.run(portfolio: portfolio, organization: new_organization)
    end
  end

  context 'When there are many existing allocations' do
    it 'evenly splits multiple allocations' do
      create_existing_allocations_with_percentages([25, 25, 25, 25])
      expect_percentages_to_update_to([20, 20, 20, 20, 20])

      Allocations::AddOrganizationAndRebalancePortfolio.run(portfolio: portfolio, organization: new_organization)
    end

    it "doesn't accidentally remove low-percentage organizations existing the portfolio" do
      create_existing_allocations_with_percentages([1, 99])
      expect_percentages_to_update_to([1, 66, 33])

      Allocations::AddOrganizationAndRebalancePortfolio.run(portfolio: portfolio, organization: new_organization)
    end

    it 'adjusts existing allocations to ensure they add to 100%' do
      create_existing_allocations_with_percentages([7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 6, 6, 6, 6, 6])
      expect_percentages_to_update_to([6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 6, 6, 6, 6, 6, 6])

      Allocations::AddOrganizationAndRebalancePortfolio.run(portfolio: portfolio, organization: new_organization)
    end
  end

  context 'When there are 100 existing allocations' do
    before { create_existing_allocations_with_percentages(Array.new(100, 1)) }

    it "doesn't let you add a new organization" do
      expect(Allocations::UpdateAllocations).not_to receive(:run)

      command = Allocations::AddOrganizationAndRebalancePortfolio.run(
        portfolio: portfolio,
        organization: new_organization
      )

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(portfolio: :balancing_would_remove_organization)
    end
  end

  def create_existing_allocations_with_percentages(percentages)
    existing_allocations = percentages.map.with_index do |percentage, i|
      Allocation.new(organization: build(:organization, ein: "existing_org_#{i}"), percentage: percentage)
    end

    expect(Allocations::GetActiveAllocations)
      .to receive(:call)
      .with(portfolio: portfolio)
      .and_return(existing_allocations)
  end

  def expect_percentages_to_update_to(percentages)
    existing_org_allocations = percentages[0...-1].map.with_index do |percentage, i|
      { organization_ein: "existing_org_#{i}", percentage: percentage }
    end
    new_org_allocation = { organization_ein: 'org_to_be_added', percentage: percentages.last }
    expected_allocations = existing_org_allocations + [new_org_allocation]

    expect(Allocations::UpdateAllocations)
      .to receive(:run)
      .with(portfolio: portfolio, allocations: expected_allocations)
      .and_return(double(success?: double))
  end
end
