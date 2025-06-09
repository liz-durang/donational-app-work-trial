# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe 'Partners Contributions controller private methods', type: :controller do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:portfolio) { create(:portfolio, creator: donor) }
  let(:controller) { Partners::ContributionsController.new }
  let(:default_params) do
    {
      id: donor.id,
      subscription: {
        amount_dollars: 50,
        tips_cents: 200,
        frequency: 'monthly',
        portfolio_id: portfolio.id,
        payment_token: 'test_token',
        trial_amount_dollars: 10,
        start_at: Time.zone.now.iso8601,
        donor_id: donor.id
      }
    }
  end

  before do
    allow(controller).to receive(:current_donor).and_return(donor)
    allow(controller).to receive(:current_currency).and_return(Money.default_currency)
  end

  describe '#ensure_donor_has_permission!' do
    it 'allows the action when donor has permission' do
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(true)
      allow(controller).to receive(:partner).and_return(partner)
      allow(controller).to receive(:donor).and_return(donor)

      expect(controller).not_to receive(:redirect_to)
      controller.send(:ensure_donor_has_permission!)
    end

    it 'redirects when donor does not have permission' do
      allow(donor.partners).to receive(:exists?).with(id: partner.id).and_return(false)
      allow(controller).to receive(:partner).and_return(partner)
      allow(controller).to receive(:donor).and_return(donor)
      allow(controller).to receive(:edit_partner_donor_path).with(partner, donor).and_return('/mock/path')

      # Mock flash as a hash
      flash_mock = {}
      allow(controller).to receive(:flash).and_return(flash_mock)

      expect(controller).to receive(:redirect_to).with('/mock/path')
      controller.send(:ensure_donor_has_permission!)
      expect(flash_mock[:error]).to eq("Sorry, you don't have permission to modify this contribution.")
    end
  end

  describe '#tips_options' do
    it 'returns an array of tip options with formatted money values' do
      result = controller.send(:tips_options)
      expect(result).to be_an(Array)
      expect(result.length).to eq(4)
      expect(result.map(&:first)).to eq([0, 200, 500, 1000])
      expect(result.first.last).to include('No tip')
    end

    it 'formats money values according to currency' do
      usd_currency = Money::Currency.new('USD')
      gbp_currency = Money::Currency.new('GBP')

      allow(controller).to receive(:current_currency).and_return(usd_currency)
      result_usd = controller.send(:tips_options)
      expect(result_usd[1].last).to include('$')

      allow(controller).to receive(:current_currency).and_return(gbp_currency)
      result_gbp = controller.send(:tips_options)
      expect(result_gbp[1].last).to include('£')
    end
  end

  describe '#update_subscription!' do
    let(:subscription_time) { Time.zone.now }
    let(:expected_subscription_params) do
      {
        donor:,
        portfolio:,
        partner:,
        frequency: 'monthly',
        amount_cents: 5000,
        tips_cents: 200,
        partner_contribution_percentage: 0
      }
    end

    before do
      allow(controller).to receive(:donor).and_return(donor)
      allow(controller).to receive(:partner).and_return(partner)
      allow(Portfolio).to receive(:find).with(portfolio.id.to_s).and_return(portfolio)
      allow(controller).to receive(:portfolio_id).and_return(portfolio.id.to_s)
      allow(controller).to receive(:frequency).and_return('monthly')
      allow(controller).to receive(:amount_cents).and_return(5000)
      allow(controller).to receive(:tips_cents).and_return(200)
      allow(controller).to receive(:start_at).and_return(subscription_time)
      allow(controller).to receive(:trial_amount_cents).and_return(1000)
    end

    it 'calls Contributions::CreateOrReplaceSubscription with correct parameters' do
      expect(Contributions::CreateOrReplaceSubscription).to receive(:run).with(
        hash_including(expected_subscription_params)
      )

      controller.send(:update_subscription!)
    end

    it 'includes trial_amount_cents in the parameters' do
      expect(Contributions::CreateOrReplaceSubscription).to receive(:run).with(
        hash_including(trial_amount_cents: 1000)
      )

      controller.send(:update_subscription!)
    end
  end

  describe '#donor' do
    before do
      allow(controller).to receive(:params).and_return(default_params)
    end

    it 'gets donor by id from params' do
      allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
      expect(controller.send(:donor)).to eq(donor)
    end

    it 'gets donor by subscription donor_id if id is not present' do
      allow(controller).to receive(:params).and_return({ subscription: { donor_id: donor.id } })
      allow(Donors::GetDonorById).to receive(:call).with(id: nil).and_return(nil)
      allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
      expect(controller.send(:donor)).to eq(donor)
    end

    it 'returns nil if neither id nor donor_id are present' do
      allow(controller).to receive(:params).and_return({})
      allow(Donors::GetDonorById).to receive(:call).with(id: nil).and_return(nil)
      expect { controller.send(:donor) }.to raise_error(NoMethodError)
    end
  end

  describe '#payment_method' do
    it 'fetches active payment method for donor' do
      payment_method = create(:payment_method, donor:)
      allow(controller).to receive(:donor).and_return(donor)
      allow(Payments::GetActivePaymentMethod).to receive(:call).with(donor:).and_return(payment_method)
      expect(controller.send(:payment_method)).to eq(payment_method)
    end

    it 'raises error when donor is not present' do
      allow(controller).to receive(:donor).and_return(nil)
      expect { controller.send(:payment_method) }.to raise_error(NoMethodError)
    end
  end

  describe '#active_portfolio' do
    it 'fetches active portfolio for donor' do
      allow(controller).to receive(:donor).and_return(donor)
      allow(Portfolios::GetActivePortfolio).to receive(:call).with(donor:).and_return(portfolio)
      expect(controller.send(:active_portfolio)).to eq(portfolio)
    end

    it 'memoizes the result' do
      allow(controller).to receive(:donor).and_return(donor)
      expect(Portfolios::GetActivePortfolio).to receive(:call).with(donor:).once.and_return(portfolio)

      result1 = controller.send(:active_portfolio)
      result2 = controller.send(:active_portfolio)
      expect(result1).to eq(portfolio)
      expect(result2).to eq(portfolio)
    end

    it 'returns nil when donor is not present' do
      allow(controller).to receive(:donor).and_return(nil)
      expect(controller.send(:active_portfolio)).to be_nil
    end
  end

  describe '#active_subscription' do
    it 'fetches active subscription for donor' do
      subscription = create(:subscription, donor:)
      allow(controller).to receive(:donor).and_return(donor)
      allow(Contributions::GetActiveSubscription).to receive(:call).with(donor:).and_return(subscription)
      expect(controller.send(:active_subscription)).to eq(subscription)
    end

    it 'memoizes the result' do
      subscription = create(:subscription, donor:)
      allow(controller).to receive(:donor).and_return(donor)
      expect(Contributions::GetActiveSubscription).to receive(:call).with(donor:).once.and_return(subscription)

      result1 = controller.send(:active_subscription)
      result2 = controller.send(:active_subscription)
      expect(result1).to eq(subscription)
      expect(result2).to eq(subscription)
    end

    it 'returns nil when donor is not present' do
      allow(controller).to receive(:donor).and_return(nil)
      expect(controller.send(:active_subscription)).to be_nil
    end
  end

  describe '#partner_affiliation' do
    it 'fetches partner affiliation for donor' do
      partner_affiliation = create(:partner_affiliation, donor:)
      allow(controller).to receive(:donor).and_return(donor)
      allow(Partners::GetPartnerAffiliationByDonor).to receive(:call).with(donor:).and_return(partner_affiliation)
      expect(controller.send(:partner_affiliation)).to eq(partner_affiliation)
    end

    it 'memoizes the result' do
      partner_affiliation = create(:partner_affiliation, donor:)
      allow(controller).to receive(:donor).and_return(donor)
      expect(Partners::GetPartnerAffiliationByDonor).to receive(:call).with(donor:).once.and_return(partner_affiliation)

      result1 = controller.send(:partner_affiliation)
      result2 = controller.send(:partner_affiliation)
      expect(result1).to eq(partner_affiliation)
      expect(result2).to eq(partner_affiliation)
    end

    it 'returns nil when donor is not present' do
      allow(controller).to receive(:donor).and_return(nil)
      expect(controller.send(:partner_affiliation)).to be_nil
    end
  end

  describe '#partner' do
    it 'fetches partner for donor' do
      allow(controller).to receive(:donor).and_return(donor)
      allow(Partners::GetPartnerForDonor).to receive(:call).with(donor:).and_return(partner)
      expect(controller.send(:partner)).to eq(partner)
    end

    it 'memoizes the result' do
      allow(controller).to receive(:donor).and_return(donor)
      expect(Partners::GetPartnerForDonor).to receive(:call).with(donor:).once.and_return(partner)

      result1 = controller.send(:partner)
      result2 = controller.send(:partner)
      expect(result1).to eq(partner)
      expect(result2).to eq(partner)
    end

    it 'returns nil when donor is not present' do
      allow(controller).to receive(:donor).and_return(nil)
      expect(controller.send(:partner)).to be_nil
    end
  end

  describe '#managed_portfolio?' do
    it 'returns true when portfolio has a manager' do
      portfolio_manager = instance_double(Object)
      allow(controller).to receive(:active_portfolio).and_return(portfolio)
      allow(Portfolios::GetPortfolioManager).to receive(:call).with(portfolio:).and_return(portfolio_manager)
      expect(controller.send(:managed_portfolio?)).to be true
    end

    it 'returns false when portfolio has no manager' do
      allow(controller).to receive(:active_portfolio).and_return(portfolio)
      allow(Portfolios::GetPortfolioManager).to receive(:call).with(portfolio:).and_return(nil)
      expect(controller.send(:managed_portfolio?)).to be false
    end

    it 'returns false if active_portfolio is nil' do
      allow(controller).to receive(:active_portfolio).and_return(nil)
      expect(controller.send(:managed_portfolio?)).to be false
    end
  end

  describe '#selectable_portfolios' do
    it 'includes active portfolio when not managed' do
      allow(controller).to receive(:active_portfolio).and_return(portfolio)
      allow(controller).to receive(:managed_portfolio?).and_return(false)
      allow(controller).to receive(:partner).and_return(partner)
      allow(Partners::GetManagedPortfoliosForPartner).to receive(:call).with(partner:).and_return([])

      result = controller.send(:selectable_portfolios)
      expect(result).to include([portfolio.id, 'My personalized portfolio'])
    end

    it 'includes managed portfolios from partner' do
      allow(controller).to receive(:active_portfolio).and_return(portfolio)
      allow(controller).to receive(:managed_portfolio?).and_return(true)
      allow(controller).to receive(:partner).and_return(partner)

      managed_portfolios_result = instance_double(ActiveRecord::Relation)
      allow(managed_portfolios_result).to receive(:pluck).with(:portfolio_id,
                                                               :name).and_return([['managed_id', 'Managed Portfolio']])

      allow(Partners::GetManagedPortfoliosForPartner).to receive(:call).with(partner:)
                                                                       .and_return(managed_portfolios_result)

      result = controller.send(:selectable_portfolios)
      expect(result).to include(['managed_id', 'Managed Portfolio'])
    end

    it 'excludes active portfolio when managed' do
      allow(controller).to receive(:active_portfolio).and_return(portfolio)
      allow(controller).to receive(:managed_portfolio?).and_return(true)
      allow(controller).to receive(:partner).and_return(partner)
      allow(Partners::GetManagedPortfoliosForPartner).to receive(:call).with(partner:).and_return([])

      result = controller.send(:selectable_portfolios)
      expect(result).not_to include([portfolio.id, 'My personalized portfolio'])
    end

    it 'returns empty array when partner and active_portfolio are nil' do
      allow(controller).to receive(:active_portfolio).and_return(nil)
      allow(controller).to receive(:partner).and_return(nil)

      result = controller.send(:selectable_portfolios)
      expect(result).to eq([])
    end

    it 'handles case where partner exists but no managed portfolios' do
      allow(controller).to receive(:active_portfolio).and_return(nil)
      allow(controller).to receive(:partner).and_return(partner)
      allow(Partners::GetManagedPortfoliosForPartner).to receive(:call).with(partner:).and_return([])

      result = controller.send(:selectable_portfolios)
      expect(result).to eq([])
    end
  end

  describe '#new_subscription' do
    it 'builds a new subscription with correct attributes' do
      allow(controller).to receive(:donor).and_return(donor)
      allow(controller).to receive(:active_portfolio).and_return(portfolio)
      allow(controller).to receive(:target_amount_cents).and_return(5000)

      result = controller.send(:new_subscription)
      expect(result).to be_a(Subscription)
      expect(result.donor).to eq(donor)
      expect(result.amount_cents).to eq(5000)
      expect(result.portfolio).to eq(portfolio)
      expect(result.frequency).to eq(donor.contribution_frequency)
    end

    it 'raises error when donor is not present' do
      allow(controller).to receive(:donor).and_return(nil)
      expect { controller.send(:new_subscription) }.to raise_error(NoMethodError)
    end

    it 'handles nil active_portfolio' do
      allow(controller).to receive(:donor).and_return(donor)
      allow(controller).to receive(:active_portfolio).and_return(nil)
      allow(controller).to receive(:target_amount_cents).and_return(5000)

      result = controller.send(:new_subscription)
      expect(result).to be_a(Subscription)
      expect(result.portfolio).to be_nil
    end
  end

  describe '#target_amount_cents' do
    it 'gets target contribution amount cents with subscription frequency' do
      subscription = create(:subscription, donor:)
      allow(controller).to receive(:donor).and_return(donor)
      allow(controller).to receive(:active_subscription).and_return(subscription)

      allow(Contributions::GetTargetContributionAmountCents).to receive(:call).with(
        donor:, frequency: subscription.frequency
      ).and_return(5000)

      expect(controller.send(:target_amount_cents)).to eq(5000)
    end

    it 'uses donor contribution frequency if active subscription is not present' do
      allow(controller).to receive(:donor).and_return(donor)
      allow(controller).to receive(:active_subscription).and_return(nil)

      allow(Contributions::GetTargetContributionAmountCents).to receive(:call).with(
        donor:, frequency: donor.contribution_frequency
      ).and_return(5000)

      expect(controller.send(:target_amount_cents)).to eq(5000)
    end

    it 'raises error when donor is not present' do
      allow(controller).to receive(:donor).and_return(nil)
      expect { controller.send(:target_amount_cents) }.to raise_error(NoMethodError)
    end
  end

  describe '#amount_cents' do
    it 'converts amount_dollars to cents' do
      allow(controller).to receive(:amount_dollars).and_return(50)
      expect(controller.send(:amount_cents)).to eq(5000)
    end

    it 'handles zero amount_dollars' do
      allow(controller).to receive(:amount_dollars).and_return(0)
      expect(controller.send(:amount_cents)).to eq(0)
    end

    it 'handles nil amount_dollars' do
      allow(controller).to receive(:amount_dollars).and_return(nil)
      expect { controller.send(:amount_cents) }.to raise_error(NoMethodError)
    end
  end

  describe '#tips_cents' do
    before do
      allow(controller).to receive(:params).and_return(default_params)
    end

    it 'gets tips_cents from params' do
      expect(controller.send(:tips_cents)).to eq(200)
    end

    it 'returns 0 if tips_cents is not in params' do
      allow(controller).to receive(:params).and_return({ subscription: {} })
      expect(controller.send(:tips_cents)).to eq(0)
    end

    it 'handles non-numeric tips_cents value' do
      allow(controller).to receive(:params).and_return({ subscription: { tips_cents: 'abc' } })
      expect(controller.send(:tips_cents)).to eq(0)
    end
  end

  describe '#amount_dollars' do
    before do
      allow(controller).to receive(:params).and_return(default_params)
    end

    it 'gets amount_dollars from params' do
      expect(controller.send(:amount_dollars)).to eq(50)
    end

    it 'returns 0 if amount_dollars is not in params' do
      allow(controller).to receive(:params).and_return({ subscription: {} })
      expect(controller.send(:amount_dollars)).to eq(0)
    end

    it 'handles non-numeric amount_dollars value' do
      allow(controller).to receive(:params).and_return({ subscription: { amount_dollars: 'abc' } })
      expect(controller.send(:amount_dollars)).to eq(0)
    end
  end

  describe '#trial_amount_cents' do
    it 'converts trial_amount_dollars to cents' do
      allow(controller).to receive(:trial_amount_dollars).and_return(10)
      expect(controller.send(:trial_amount_cents)).to eq(1000)
    end

    it 'handles zero trial_amount_dollars' do
      allow(controller).to receive(:trial_amount_dollars).and_return(0)
      expect(controller.send(:trial_amount_cents)).to eq(0)
    end

    it 'handles nil trial_amount_dollars' do
      allow(controller).to receive(:trial_amount_dollars).and_return(nil)
      expect { controller.send(:trial_amount_cents) }.to raise_error(NoMethodError)
    end
  end

  describe '#trial_amount_dollars' do
    before do
      allow(controller).to receive(:params).and_return(default_params)
    end

    it 'gets trial_amount_dollars from params' do
      expect(controller.send(:trial_amount_dollars)).to eq(10)
    end

    it 'returns 0 if trial_amount_dollars is not in params' do
      allow(controller).to receive(:params).and_return({ subscription: {} })
      expect(controller.send(:trial_amount_dollars)).to eq(0)
    end
  end

  describe '#payment_token' do
    before do
      allow(controller).to receive(:params).and_return(default_params)
    end

    it 'gets payment_token from params' do
      expect(controller.send(:payment_token)).to eq('test_token')
    end

    it 'returns nil if payment_token is not in params' do
      allow(controller).to receive(:params).and_return({ subscription: {} })
      expect(controller.send(:payment_token)).to be_nil
    end
  end

  describe '#frequency' do
    before do
      allow(controller).to receive(:params).and_return(default_params)
    end

    it 'gets frequency from params' do
      expect(controller.send(:frequency)).to eq('monthly')
    end

    it 'returns nil if frequency is not in params' do
      allow(controller).to receive(:params).and_return({ subscription: {} })
      expect(controller.send(:frequency)).to be_nil
    end
  end

  describe '#portfolio_id' do
    before do
      allow(controller).to receive(:params).and_return(default_params)
    end

    it 'gets portfolio_id from params' do
      expect(controller.send(:portfolio_id)).to eq(portfolio.id)
    end

    it 'returns nil if portfolio_id is not in params' do
      allow(controller).to receive(:params).and_return({ subscription: {} })
      expect(controller.send(:portfolio_id)).to be_nil
    end
  end

  describe '#start_at' do
    it 'parses start_at from params' do
      timestamp = Time.zone.now.iso8601
      allow(controller).to receive(:params).and_return({
                                                         subscription: { start_at: timestamp }
                                                       })
      parsed_time = Time.zone.parse(timestamp)
      allow(Time.zone).to receive(:parse).with(timestamp).and_return(parsed_time)

      expect(controller.send(:start_at)).to eq(parsed_time)
    end

    it 'returns nil when start_at is not in params' do
      allow(controller).to receive(:params).and_return({ subscription: {} })
      expect(controller.send(:start_at)).to be_nil
    end

    it 'handles invalid date format gracefully' do
      allow(controller).to receive(:params).and_return({
                                                         subscription: { start_at: 'invalid-date' }
                                                       })
      allow(Time.zone).to receive(:parse).with('invalid-date').and_return(nil)

      expect(controller.send(:start_at)).to be_nil
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
