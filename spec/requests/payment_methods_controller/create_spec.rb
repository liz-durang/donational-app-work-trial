require 'rails_helper'

RSpec.describe 'POST /payment_methods', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:payment_method_params) do
    {
      payment_token: 'test_token',
      payment_method_id: 'pm_test',
      customer_id: 'cus_test'
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
  end

  context 'when the payment method is updated successfully' do
    before do
      allow(Payments::UpdatePaymentMethod).to receive(:run).and_return(successful_outcome)
    end

    it 'redirects to the edit accounts path' do
      post payment_methods_path, params: payment_method_params
      expect(response).to redirect_to(edit_accounts_path)
    end

    it 'sets a flash success message' do
      post payment_methods_path, params: payment_method_params
      expect(flash[:success]).to eq("Thanks, we've updated your payment information")
    end
  end

  context 'when the payment method update fails' do
    before do
      allow(Payments::UpdatePaymentMethod).to receive(:run).and_return(failure_outcome)
    end

    it 'redirects to the edit accounts path' do
      post payment_methods_path, params: payment_method_params
      expect(response).to redirect_to(edit_accounts_path)
    end

    it 'sets a flash error message' do
      post payment_methods_path, params: payment_method_params
      expect(flash[:error]).to eq('Error message')
    end
  end
end
