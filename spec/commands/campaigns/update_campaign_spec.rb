require 'rails_helper'

RSpec.describe Campaigns::UpdateCampaign do
  let(:partner) { create(:partner, uses_one_for_the_world_checkout:) }
  let(:campaign) { create(:campaign, allow_one_time_contributions: false, partner:) }
  let(:updateable_attributes) do
    { title: 'New Title', campaign:, description: 'New Description', slug: 'new-slug',
      minimum_contribution_amount: 100, default_contribution_amounts: [100, 200, 300], allow_one_time_contributions: }
  end
  let(:allow_one_time_contributions) { false }

  context 'when partner uses one for the world checkout' do
    let(:uses_one_for_the_world_checkout) { true }

    it 'does not require default contribution amounts or allow_one_time_contributions flag' do
      result = described_class.run(updateable_attributes.except(:default_contribution_amounts,
                                                                :allow_one_time_contributions))

      expect(result).to be_success
    end

    context 'when allow_one_time_contributions is omitted' do
      it 'does not change the allow_one_time_contributions attribute' do
        original_value = campaign.allow_one_time_contributions
        result = described_class.run(updateable_attributes.except(:allow_one_time_contributions))

        expect(result).to be_success
        expect(campaign.reload.allow_one_time_contributions).to eq(original_value)
      end
    end
  end

  context 'when partner does not use one for the world checkout' do
    let(:uses_one_for_the_world_checkout) { false }

    it 'requires default contribution amounts and allow_one_time_contributions flag' do
      result_without_default_contribution_amounts = described_class.run(updateable_attributes.except(:default_contribution_amounts))
      result_without_allow_one_time_contributions = described_class.run(updateable_attributes.except(:allow_one_time_contributions))

      expect(result_without_default_contribution_amounts).not_to be_success
      expect(result_without_allow_one_time_contributions).not_to be_success
      expect(result_without_default_contribution_amounts.errors.symbolic).to include(campaign: :default_contribution_amounts)
      expect(result_without_allow_one_time_contributions.errors.symbolic).to include(campaign: :allow_one_time_contributions)
    end

    context 'when allow_one_time_contributions is passed in as true' do
      it 'updates the campaign to allow one-time contributions' do
        result = described_class.run(updateable_attributes.merge(allow_one_time_contributions: true))

        expect(result).to be_success
        expect(campaign.reload.allow_one_time_contributions).to be(true)
      end
    end

    context 'when allow_one_time_contributions is passed in as false' do
      it 'updates the campaign to not allow one-time contributions' do
        result = described_class.run(updateable_attributes.merge(allow_one_time_contributions: false))

        expect(result).to be_success
        expect(campaign.reload.allow_one_time_contributions).to be(false)
      end
    end
  end
end
