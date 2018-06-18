require 'rails_helper'

RSpec.describe Partners::UpdateCustomDonorInformation do
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  context 'when the donor is not affiliated with the partner' do
    before do
      expect(PartnerAffiliation)
        .to receive(:find_by)
        .with(donor: donor, partner: partner)
        .and_return(nil)
    end

    it 'fails with an error' do
      command = Partners::UpdateCustomDonorInformation.run(donor: donor, partner: partner, responses: { some: 'response' })
      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(donor: :not_affiliated_with_this_partner)
    end
  end

  context 'when the donor is affiliated with this partner' do
    let(:partner_affiliation) do
      create(:partner_affiliation, custom_donor_info: custom_donor_info)
    end

    before do
      allow(PartnerAffiliation)
        .to receive(:find_by)
        .with(donor: donor, partner: partner)
        .and_return(partner_affiliation)
    end

    context 'and the responses are not strings' do
      let(:custom_donor_info) { nil }
      let(:responses) do
        { 'valid question' => 'valid response', 'boolean_response' => true }
      end

      it 'fails with an error' do
        command = Partners::UpdateCustomDonorInformation.run(donor: donor, partner: partner, responses: responses)
        expect(command).not_to be_success
        expect(command.errors.message[:responses]).to include(boolean_response: "Boolean Response isn't a string")
      end
    end

    context 'and the responses are very long strings' do
      let(:custom_donor_info) { nil }
      let(:responses) do
        { 'question' => 'with long answer' * 20 }
      end

      it 'fails with an error' do
        command = Partners::UpdateCustomDonorInformation.run(donor: donor, partner: partner, responses: responses)
        expect(command).not_to be_success
        expect(command.errors.symbolic).to include(responses: { 'question' => :max_length })
      end
    end

    context 'and there is no existing custom_donor_info' do
      let(:custom_donor_info) { nil }

      it 'saves the custom donor information' do
        responses = { 'valid question' => 'valid response', 'another question' => 'another valid response' }

        command = Partners::UpdateCustomDonorInformation.run(donor: donor, partner: partner, responses: responses)

        expect(command).to be_success

        expect(partner_affiliation.reload.custom_donor_info).to eq ({
          'valid question' => 'valid response',
          'another question' => 'another valid response',
        })
      end
    end

    context 'and there are existing custom_donor_info responses' do
      let(:custom_donor_info) { { existing_q: 'existing answer', question_to_update: 'v1' } }

      it 'merges the new responses with the existing custom donor information' do
        responses = { question_to_update: 'v2', new_question: 'to be added' }

        command = Partners::UpdateCustomDonorInformation.run(donor: donor, partner: partner, responses: responses)

        expect(command).to be_success

        expect(partner_affiliation.reload.custom_donor_info).to eq ({
          'existing_q' => 'existing answer', 'question_to_update' => 'v2', 'new_question' => 'to be added'
        })
      end
    end
  end
end
