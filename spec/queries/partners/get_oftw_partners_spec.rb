require 'rails_helper'

RSpec.describe Partners::GetOftwPartners, type: :query do
  let!(:active_partner1) { create(:partner, deactivated_at: nil, uses_one_for_the_world_checkout: true, name: 'Partner A') }
  let!(:active_partner2) { create(:partner, deactivated_at: nil, uses_one_for_the_world_checkout: true, name: 'Partner B') }
  let!(:inactive_partner) { create(:partner, deactivated_at: 1.day.ago, uses_one_for_the_world_checkout: true) }
  let!(:non_oftw_partner) { create(:partner, deactivated_at: nil, uses_one_for_the_world_checkout: false) }

  describe '#call' do
    subject { described_class.new.call }

    it 'returns active partners that use One for the World checkout, ordered by name' do
      expect(subject).to eq([active_partner1, active_partner2])
    end

    it 'does not return inactive partners' do
      expect(subject).not_to include(inactive_partner)
    end

    it 'does not return partners that do not use One for the World checkout' do
      expect(subject).not_to include(non_oftw_partner)
    end
  end
end
