require 'rails_helper'

RSpec.describe 'POST /partners/:partner_id/payment_methods', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:payment_method_params) do
    {
      id: donor.id,
      payment_token: 'test_token',
      payment_method_id: 'pm_test'
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Partners::GetPartnerById).to receive(:call).with(id: partner.id).and_return(partner)
    allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
    allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(true)
  end

  context 'when the payment method is updated successfully' do
    before do
      allow(Payments::UpdatePaymentMethod).to receive(:run).and_return(successful_outcome)
    end

    it 'redirects to the edit partner donor path' do
      post partner_payment_methods_path(partner_id: partner.id), params: payment_method_params
      expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
      expect(flash[:success]).to eq("Thanks, we've updated this donor's payment information")
    end
  end

  context 'when the payment method update fails' do
    before do
      allow(Payments::UpdatePaymentMethod).to receive(:run).and_return(failure_outcome)
    end

    it 'redirects to the edit partner donor path' do
      post partner_payment_methods_path(partner_id: partner.id), params: payment_method_params
      expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
      expect(flash[:error]).to eq('Error message')
    end
  end
end
