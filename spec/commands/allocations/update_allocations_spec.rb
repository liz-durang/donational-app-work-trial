require 'rails_helper'

RSpec.describe Allocations::UpdateAllocations do
  let(:command_params) do
    {
      portfolio: portfolio,
      allocations: allocations
    }
  end
  let(:portfolio) { create(:portfolio) }
  let(:other_portfolio) { create(:portfolio) }

  context 'when there are no allocations supplied' do
    let(:allocations) { nil }

    it 'does not run, and includes a nil allocations error' do
      command = Allocations::UpdateAllocations.run(command_params)

      expect(command).not_to be_success
      errors = command.errors.symbolic
      expect(errors).to include(allocations: :nils)
    end
  end

  context 'when the allocation percentages do not add up to 100' do
    let(:allocations) do
      [
        { organization_ein: 'foo', percentage: 20 },
        { organization_ein: 'bar', percentage: 79 }
      ]
    end

    it 'does not run, and includes an error' do
      command = Allocations::UpdateAllocations.run(command_params)

      expect(command).not_to be_success
      errors = command.errors.symbolic
      expect(errors).to include(allocations: :add_up_to_one_hundred_percent)
    end
  end

  context 'when the allocation percentages add up to 100' do
    let!(:organization_1) { Organization.create!(ein: 'foo', name: 'Foo') }
    let!(:organization_2) { Organization.create!(ein: 'bar', name: 'Bar') }
    let!(:organization_3) { Organization.create!(ein: 'should_be_excluded', name: 'Baz') }

    let(:allocations) do
      [
        { organization_ein: 'foo', percentage: 20 },
        { organization_ein: 'bar', percentage: 80 },
        { organization_ein: 'should_be_excluded', percentage: 0 }
      ]
    end

    context 'and there are no existing allocations for the portfolio' do
      it 'creates a new set of allocations' do
        expect { Allocations::UpdateAllocations.run(command_params) }
          .to change { Allocation.count }.from(0).to(2)

        foo = Allocation.where(organization_ein: 'foo').first
        bar = Allocation.where(organization_ein: 'bar').first
        expect(foo.percentage).to eq 20
        expect(foo.portfolio).to eq portfolio
        expect(foo).to be_active
        expect(bar.percentage).to eq 80
        expect(bar.portfolio).to eq portfolio
        expect(bar).to be_active
      end
    end

    context 'when there are existing allocations for the portfolio' do
      let!(:existing_allocation_1) do
        Allocation.create!(
          organization: organization_1, portfolio: portfolio, percentage: 75
        )
      end
      let!(:existing_allocation_2) do
        Allocation.create!(
          organization: organization_2, portfolio: portfolio, percentage: 25
        )
      end
      let!(:existing_allocation_other_portfolio) do
        Allocation.create!(
          organization: organization_1, portfolio: other_portfolio, percentage: 100
        )
      end

      it 'deactivates the previous allocations for the portfolio' do
        Allocations::UpdateAllocations.run(command_params)
        expect(existing_allocation_1.reload).not_to be_active
        expect(existing_allocation_2.reload).not_to be_active
        expect(existing_allocation_other_portfolio.reload).to be_active
      end

      it 'creates a new set of allocations' do
        expect { Allocations::UpdateAllocations.run(command_params) }
          .to change { Allocation.count }.by(2)
      end
    end
  end
end
