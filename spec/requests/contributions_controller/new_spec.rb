require 'rails_helper'

RSpec.describe 'GET /contributions/new', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:subscription) { create(:subscription, donor:) }
  let(:trial_subscription) do
    create(:subscription, donor:, trial_start_at: Time.current, trial_amount_cents: 500)
  end
  let(:payment_method) { create(:payment_method, donor:) }
  let(:partner_affiliation) { create(:partner_affiliation, donor:) }
  let(:partner) { partner_affiliation.partner }
  let(:portfolio) { create(:portfolio) }
  let(:currency) { Money.default_currency }

  before do
    login_as(donor)
    allow_any_instance_of(ApplicationController).to receive(:current_donor).and_return(donor)
    allow(Payments::GetActivePaymentMethod).to receive(:call).with(donor:).and_return(payment_method)
    allow(Portfolios::GetActivePortfolio).to receive(:call).with(donor:).and_return(portfolio)
    allow(Contributions::GetActiveTrial).to receive(:call).with(donor:).and_return(trial_subscription)
    allow(Contributions::GetActiveSubscription).to receive(:call).with(donor:).and_return(subscription)
    allow(Partners::GetPartnerAffiliationByDonor).to receive(:call).with(donor:).and_return(partner_affiliation)
    allow(Partners::GetPartnerForDonor).to receive(:call).with(donor:).and_return(partner)
    allow(Contributions::GetTargetContributionAmountCents).to receive(:call).with(
      donor:, frequency: subscription.frequency
    ).and_return(subscription.amount_cents)
    allow_any_instance_of(ApplicationController).to receive(:current_currency).and_return(currency)
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
    expect(assigns(:view_model).subscription).to be_a(Subscription)
    expect(assigns(:view_model).active_payment_method?).to eq(payment_method.present?)
    expect(assigns(:view_model).payment_method).to eq(payment_method)
    expect(assigns(:view_model).partner_affiliation).to eq(partner_affiliation)
    expect(assigns(:view_model).partner_affiliation?).to eq(partner_affiliation.present?)
    expect(assigns(:view_model).currency_code).to eq(currency.iso_code)
    expect(assigns(:view_model).amount_cents).to eq(subscription.amount_cents)
    expect(assigns(:view_model).tips_options).to eq([0, 200, 500, 1000].map do |amount|
                                                      [amount,
                                                       Money.new(amount, currency).format(no_cents_if_whole: true,
                                                                                          display_free: 'No tip')]
                                                    end)
    expect(assigns(:view_model).show_plaid?).to eq(partner.supports_plaid?)
  end
end
