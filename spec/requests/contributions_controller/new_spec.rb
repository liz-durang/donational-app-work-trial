require 'rails_helper'

RSpec.describe 'GET /contributions/new', type: :request do
  include Helpers::LoginHelper
  let(:donor) { create(:donor) }
  let(:subscription) { create(:subscription, donor: donor) }
  let(:payment_method) { create(:payment_method, donor: donor) }
  let(:partner_affiliation) { create(:partner_affiliation, donor: donor) }
  let(:currency) { Money.default_currency }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow_any_instance_of(ContributionsController).to receive(:new_subscription).and_return(subscription)
    allow_any_instance_of(ContributionsController).to receive(:payment_method).and_return(payment_method)
    allow_any_instance_of(ContributionsController).to receive(:partner_affiliation).and_return(partner_affiliation)
    allow_any_instance_of(ContributionsController).to receive(:current_currency).and_return(currency)
    allow_any_instance_of(ContributionsController).to receive(:target_amount_cents).and_return(subscription.amount_cents)

  end

  it 'returns a successful response' do
    get new_contribution_path
    expect(response).to have_http_status(:success)
  end

  it 'renders the new template' do
    get new_contribution_path
    expect(response).to render_template(:new)
  end

  it 'assigns the correct view model' do
    get new_contribution_path
    expect(assigns(:view_model).target_amount_cents).to eq(subscription.amount_cents)
    expect(assigns(:view_model).subscription).to eq(subscription)
    expect(assigns(:view_model).active_payment_method?).to eq(payment_method.present?)
    expect(assigns(:view_model).payment_method).to eq(payment_method)
    expect(assigns(:view_model).partner_affiliation).to eq(partner_affiliation)
    expect(assigns(:view_model).partner_affiliation?).to eq(partner_affiliation.present?)
    expect(assigns(:view_model).currency_code).to eq(currency.iso_code)
    expect(assigns(:view_model).amount_cents).to eq(subscription.amount_cents)
    expect(assigns(:view_model).tips_options).to eq([0, 200, 500, 1000].map { |amount| [amount, Money.new(amount, currency).format(no_cents_if_whole: true, display_free: 'No tip')] })
    expect(assigns(:view_model).show_plaid?).to eq(partner_affiliation.partner.supports_plaid?)
  end
end
