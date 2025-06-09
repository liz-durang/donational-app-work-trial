require 'rails_helper'

RSpec.describe 'PUT /partners/:id', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper
  include Helpers::MediaHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:partner_params) do
    {
      partner: {
        name: 'Updated Partner Name',
        website_url: 'https://updated-website.com',
        description: 'Updated description',
        email_receipt_preamble: 'Updated preamble',
        receipt_first_paragraph: 'Updated first paragraph',
        receipt_second_paragraph: 'Updated second paragraph',
        receipt_tax_info: 'Updated tax info',
        receipt_charity_name: 'Updated charity name',
        after_donation_thank_you_page_url: 'https://updated-thank-you.com',
        logo: sample_image,
        email_banner: sample_image
      },
      donor_questions: {
        '0' => {
          name: 'question_1',
          title: 'Question 1',
          type: 'text',
          options: '',
          required: '1'
        }
      }
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(PartnersController).to receive(:partner).and_return(partner)
    allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
  end

  context 'when the donor does not have permission' do
    let(:other_partner) { create(:partner) }
    let(:partner_params_for_other_partner) do
      {
        partner: {
          name: 'Updated Partner Name'
        }
      }
    end

    before do
      # This call to partner in the main before block will set @partner to the original partner
      # We need to ensure that when the controller action calls partner, it gets other_partner
      allow_any_instance_of(PartnersController).to receive(:partner).and_return(other_partner)
      # And the current_donor has no association to 'other_partner'
      allow(donor).to receive(:partners).and_return(Partner.none) # or Partner.where(id: partner.id) if partner is different from other_partner
    end

    it 'redirects to the edit partner path of the accessed partner' do
      put partner_path(other_partner), params: partner_params_for_other_partner
      expect(response).to redirect_to(edit_partner_path(other_partner))
    end

    it 'sets a flash error message' do
      put partner_path(other_partner), params: partner_params_for_other_partner
      expect(flash[:error]).to eq("Sorry, you don't have permission to update this partner account")
    end

    it 'does not call UpdatePartner or UpdateCustomDonorQuestions' do
      expect(Partners::UpdatePartner).not_to receive(:run)
      expect(Partners::UpdateCustomDonorQuestions).not_to receive(:run)
      put partner_path(other_partner), params: partner_params_for_other_partner
    end
  end

  context 'when the update is successful' do
    before do
      allow(Partners::UpdatePartner).to receive(:run).and_return(successful_outcome)
      allow(Partners::UpdateCustomDonorQuestions).to receive(:run).and_return(successful_outcome)
    end

    it 'redirects to the edit partner path' do
      put partner_path(partner), params: partner_params
      expect(response).to redirect_to(edit_partner_path(partner))
    end

    it 'sets a flash success message' do
      put partner_path(partner), params: partner_params
      expect(flash[:success]).to eq("Thanks, we've updated your information")
    end
  end

  context 'when the update fails' do
    before do
      allow(Partners::UpdatePartner).to receive(:run).and_return(failure_outcome)
      allow(Partners::UpdateCustomDonorQuestions).to receive(:run).and_return(failure_outcome)
    end

    it 'redirects to the edit partner path' do
      put partner_path(partner), params: partner_params
      expect(response).to redirect_to(edit_partner_path(partner))
    end

    it 'sets a flash error message' do
      put partner_path(partner), params: partner_params
      expect(flash[:error]).to eq('Error message')
    end
  end
end
