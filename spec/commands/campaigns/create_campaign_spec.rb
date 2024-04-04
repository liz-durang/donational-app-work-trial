require 'rails_helper'

RSpec.describe Campaigns::CreateCampaign do
  let(:partner) { create(:partner, uses_one_for_the_world_checkout:) }
  let(:campaign_attributes) do
    {
      partner:,
      slug: 'new-campaign',
      minimum_contribution_amount: 50,
      default_contribution_amounts: [100, 200, 300],
      allow_one_time_contributions: true
    }
  end

  context 'when partner uses one for the world checkout' do
    let(:uses_one_for_the_world_checkout) { true }

    it 'does not require default contribution amounts or allow_one_time_contributions flag' do
      result = described_class.run(campaign_attributes.except(:default_contribution_amounts,
                                                              :allow_one_time_contributions))

      expect(result).to be_success
    end
  end

  context 'when partner does not use one for the world checkout' do
    let(:uses_one_for_the_world_checkout) { false }

    it 'requires default contribution amounts and allow_one_time_contributions flag' do
      result_without_default_contribution_amounts = described_class.run(campaign_attributes.except(:default_contribution_amounts))
      result_without_allow_one_time_contributions = described_class.run(campaign_attributes.except(:allow_one_time_contributions))

      expect(result_without_default_contribution_amounts).not_to be_success
      expect(result_without_allow_one_time_contributions).not_to be_success
      expect(result_without_default_contribution_amounts.errors.symbolic).to include(campaign: :default_contribution_amounts)
      expect(result_without_allow_one_time_contributions.errors.symbolic).to include(campaign: :allow_one_time_contributions)
    end
  end
end
