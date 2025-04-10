require 'rails_helper'

RSpec.describe 'DELETE /partners/:partner_id/contributions/:id', type: :request do
  include Helpers::LoginHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:contribution) { create(:contribution, donor: donor, partner: partner) }
  let(:portfolio) { create(:portfolio, creator: donor) }
  let(:subscription) { create(:subscription, donor: donor, portfolio: portfolio) }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Partners::GetPartnerById).to receive(:call).with(id: partner.id).and_return(partner)
    allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
    allow(Partners::GetPartnerForDonor).to receive(:call).with(donor: donor).and_return(partner)
    allow(Contributions::GetActiveSubscription).to receive(:call).with(donor: donor).and_return(subscription)
  end

  context 'when the donor has permission' do
    let(:confirmations_mailer) { double(ConfirmationsMailer) }
    before do
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(true)
      allow(ConfirmationsMailer).to receive(:send_confirmation).and_return(confirmations_mailer)
      allow(confirmations_mailer).to receive(:deliver_now)
    end

    it 'sends an email to the donor' do
      expect(ConfirmationsMailer).to receive(:send_confirmation)
      delete partner_contribution_path(partner_id: partner.id, id: donor.id)
    end

    it 'destroys the contribution and redirects to the edit partner donor path' do
      delete partner_contribution_path(partner_id: partner.id, id: donor.id)
      expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
      expect(flash[:success]).to eq("We've cancelled the donation plan")
    end
  end

  context 'when the donor does not have permission' do
    before do
      allow(donor).to receive(:partners).and_return(Partner.where(id: partner.id))
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(false)
    end

    it 'does not destroy the contribution and redirects to the edit partner donor path with error' do
      delete partner_contribution_path(partner_id: partner.id, id: donor.id)
      expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
      expect(flash[:error]).to eq("Sorry, you don't have permission to modify this contribution.")
    end
  end
end
