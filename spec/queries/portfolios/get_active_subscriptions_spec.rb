require 'rails_helper'

RSpec.describe Portfolios::GetActivePortfolios do
  let(:other_donor) { create(:donor) }
  let(:donor) { create(:donor) }

  subject { Portfolios::GetActivePortfolios.call(donor: donor) }

  context 'when there are no portfolios for the donor' do
    before { create(:portfolio, donor: other_donor) }

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context "when all of the donor's portfolios have been deactivated" do
    before do
      create(:portfolio, donor: donor, deactivated_at: 2.days.ago)
      create(:portfolio, donor: donor, deactivated_at: 1.day.ago)
    end

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context 'when there is an existing active portfolios' do
    before do
      create(:portfolio, donor: donor, deactivated_at: 2.days.ago)
      create(:portfolio, donor: donor, deactivated_at: 1.day.ago)
    end

    let!(:portfolio) do
      create(:portfolio, donor: donor, deactivated_at: nil)
    end

    it 'returns the active portfolio' do
      expect(subject).to be_a ActiveRecord::Relation
      expect(subject).to eq [portfolio]
    end
  end
end
