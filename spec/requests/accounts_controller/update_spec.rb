require 'rails_helper'

RSpec.describe 'PUT /accounts', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:valid_params) do
    {
      donor: {
        title: 'Mr.',
        first_name: 'John',
        last_name: 'Doe',
        email: 'john.doe@example.com',
        house_name_or_number: '123',
        postcode: '12345',
        uk_gift_aid_accepted: true
      },
      donor_responses: {
        question1: 'Answer 1',
        question2: 'Answer 2'
      }
    }
  end

  before do
    login_as(donor)
    allow_any_instance_of(AccountsController).to receive(:partner).and_return(partner)
  end

  context 'when the request is valid' do
    before do
      allow(Donors::UpdateDonor).to receive(:run).and_return(successful_outcome)
      allow(Partners::UpdateCustomDonorInformation).to receive(:run).and_return(successful_outcome)
    end

    it 'updates the donor and returns a success message' do
      put '/accounts', params: valid_params
      expect(response).to redirect_to(edit_accounts_path)
      follow_redirect!
      expect(CGI.unescapeHTML(response.body)).to include("Thanks, we've updated your information")
    end
  end

  context 'when the request is invalid' do
    before do
      allow(Donors::UpdateDonor).to receive(:run).and_return(failure_outcome)
      allow(Partners::UpdateCustomDonorInformation).to receive(:run).and_return(failure_outcome)
    end

    it 'returns an error message' do
      put '/accounts', params: valid_params
      expect(response).to redirect_to(edit_accounts_path)
      follow_redirect!
      expect(response.body).to include('Error message')
    end
  end
end
