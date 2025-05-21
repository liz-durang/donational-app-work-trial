require 'rails_helper'

RSpec.describe 'POST /partners/:partner_id/refunds', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  subject(:make_request) do
    post partner_refunds_path(partner_id: partner.id)
  end

  let(:partner) { create(:partner) }
  let(:donor) { create(:donor) }
  let(:contribution) { create(:contribution, donor:, partner:) }

  before do
    allow(Contributions::GetContributionById).to receive(:call).and_return(contribution)
  end

  context 'when the contribution has not been granted' do
    before do
      login_as(donor)
      allow(Donations::AlreadyBeenGranted).to receive(:call).with(contribution:).and_return(false)
    end

    context 'when refund is successful' do
      it 'redirects to the edit donor page with a success flash' do
        allow(Contributions::RefundContribution).to receive(:run).with(contribution:).and_return(successful_outcome)
        make_request
        expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
        expect(flash[:success]).to eq('Contribution Refunded Successfully')
      end
    end

    context 'when refund fails' do
      it 'redirects to the edit donor page with an error flash' do
        allow(Contributions::RefundContribution).to receive(:run).with(contribution:).and_return(failure_outcome)
        make_request
        expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
        expect(flash[:error]).to eq('Error message')
      end
    end
  end

  context 'when the contribution has already been granted' do
    before { login_as(donor) }

    it 'redirects to the edit donor page with an error flash' do
      allow(Donations::AlreadyBeenGranted).to receive(:call).with(contribution:).and_return(true)
      make_request
      expect(response).to redirect_to(edit_partner_donor_path(partner, donor))
      message = 'This contribution could not be refunded, as it ' \
                'has already been assigned to one or more grants to organizations'
      expect(flash[:error]).to eq message
    end
  end
end
