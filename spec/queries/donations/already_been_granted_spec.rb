require 'rails_helper'

RSpec.describe Donations::AlreadyBeenGranted do
  let(:contribution) { create(:contribution) }

  context 'when all the donations have already been granted' do
    let(:grant) { create(:grant) }
    before do
      create(:donation, contribution: contribution, grant: grant)
      create(:donation, contribution: contribution, grant: grant)
    end
    it 'returns true' do
      expect(described_class.call(contribution: contribution)).to eq true
    end
  end

  context 'when some donations have already been granted' do
    let(:grant) { create(:grant) }
    before do
      create(:donation, contribution: contribution, grant: grant)
      create(:donation, contribution: contribution, grant: nil)
    end

    it 'returns true' do
      expect(described_class.call(contribution: contribution)).to eq true
    end
  end

  context 'when all the donations have not been granted' do
    before do
      create(:donation, contribution: contribution, grant: nil)
      create(:donation, contribution: contribution, grant: nil)
    end

    it 'returns false' do
      expect(described_class.call(contribution: contribution)).to eq false
    end
  end
end
