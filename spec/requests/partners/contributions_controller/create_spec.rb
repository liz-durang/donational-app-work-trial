require 'rails_helper'

RSpec.describe 'POST /partners/:partner_id/contributions', type: :request do
  include Helpers::LoginHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:portfolio) { create(:portfolio, creator: donor) }
  let(:payment_method) { create(:payment_method, donor:) }
  let(:contribution_params) do
    {
      id: donor.id,
      subscription: {
        amount_dollars: 100,
        frequency: 'monthly',
        payment_token: 'test_token',
        portfolio_id: portfolio.id,
        tips_cents: 200,
        start_at: '2023-10-01T00:00:00Z'
      }
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Partners::GetPartnerById).to receive(:call).with(id: partner.id).and_return(partner)
    allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
    allow(Partners::GetPartnerForDonor).to receive(:call).with(donor:).and_return(partner)
    allow(Payments::GetActivePaymentMethod).to receive(:call).with(donor:).and_return(payment_method)
  end

  context 'when the donor has permission' do
    let(:confirmations_mailer) { double(ConfirmationsMailer) }

    before do
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(true)
      allow(ConfirmationsMailer).to receive(:send_confirmation).and_return(confirmations_mailer)
      allow(confirmations_mailer).to receive(:deliver_now)
    end

    context 'when subscription creation succeeds' do
      it 'sends an email to the donor' do
        expect(ConfirmationsMailer).to receive(:send_confirmation)
        post partner_contributions_path(partner_id: partner.id), params: contribution_params
      end

      it 'creates a contribution and redirects to the edit partner donor path' do
        post partner_contributions_path(partner_id: partner.id), params: contribution_params
        expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
        expect(flash[:success]).to eq("We've updated your donation plan")
      end
    end

    context 'when subscription creation fails' do
      include Helpers::CommandHelper

      before do
        allow_any_instance_of(Flow).to receive(:run).and_return(failure_outcome)
      end

      it 'redirects to the edit partner donor path with error message' do
        post partner_contributions_path(partner_id: partner.id), params: contribution_params
        expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
        expect(flash[:alert]).to eq('Error message')
      end
    end
  end

  context 'when the donor does not have permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(false)
    end

    it 'does not create a contribution and redirects to the edit partner donor path with error' do
      post partner_contributions_path(partner_id: partner.id), params: contribution_params
      expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
      expect(flash[:error]).to eq("Sorry, you don't have permission to modify this contribution.")
    end
  end
end
