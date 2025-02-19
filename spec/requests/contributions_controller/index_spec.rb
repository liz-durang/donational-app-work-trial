require 'rails_helper'

RSpec.describe 'GET /contributions', type: :request do
  include Helpers::LoginHelper
  let(:donor) { create(:donor) }
  let(:contributions) { create_list(:contribution, 3, donor: donor) }
  let(:first_contribution) { contributions.first }
  let(:subscription) { create(:subscription, donor: donor) }
  let(:currency) { Money.default_currency }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Contributions::GetContributions).to receive(:call).and_return(contributions)
    allow(Contributions::GetFirstContribution).to receive(:call).and_return(first_contribution)
    allow_any_instance_of(ContributionsController).to receive(:active_subscription).and_return(subscription)
    allow_any_instance_of(ContributionsController).to receive(:current_currency).and_return(currency)
  end

  it 'assigns the correct view model' do
    get contributions_path
    expect(assigns(:view_model).contributions).to eq(contributions)
    expect(assigns(:view_model).first_contribution).to eq(first_contribution)
    expect(assigns(:view_model).subscription).to eq(subscription)
    expect(assigns(:view_model).currency).to eq(currency)
  end
end
