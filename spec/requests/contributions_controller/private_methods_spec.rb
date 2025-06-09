require 'rails_helper'

RSpec.describe ContributionsController, type: :controller do
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
  let(:controller) { ContributionsController.new }

  before do
    allow(controller).to receive(:current_donor).and_return(donor)
    allow(controller).to receive(:params).and_return({
                                                       subscription: {
                                                         amount_dollars: 50,
                                                         tips_cents: 200,
                                                         frequency: 'monthly',
                                                         portfolio_id: portfolio.id,
                                                         payment_token: 'test_token',
                                                         trial_amount_dollars: 10,
                                                         start_at: Time.zone.now.iso8601
                                                       }
                                                     })
    allow(controller).to receive(:current_currency).and_return(currency)
  end

  describe '#payment_method' do
    it 'fetches active payment method for donor' do
      expect(Payments::GetActivePaymentMethod).to receive(:call).with(donor:).and_return(payment_method)
      expect(controller.send(:payment_method)).to eq(payment_method)
    end
  end

  describe '#active_portfolio' do
    it 'fetches active portfolio for donor' do
      expect(Portfolios::GetActivePortfolio).to receive(:call).with(donor:).and_return(portfolio)
      expect(controller.send(:active_portfolio)).to eq(portfolio)
    end
  end

  describe '#active_trial' do
    it 'fetches active trial for donor' do
      expect(Contributions::GetActiveTrial).to receive(:call).with(donor:).and_return(trial_subscription)
      expect(controller.send(:active_trial)).to eq(trial_subscription)
    end
  end

  describe '#active_subscription' do
    it 'fetches active subscription for donor' do
      expect(Contributions::GetActiveSubscription).to receive(:call).with(donor:).and_return(subscription)
      expect(controller.send(:active_subscription)).to eq(subscription)
    end
  end

  describe '#partner_affiliation' do
    it 'fetches partner affiliation for donor' do
      expect(Partners::GetPartnerAffiliationByDonor).to receive(:call).with(donor:).and_return(partner_affiliation)
      expect(controller.send(:partner_affiliation)).to eq(partner_affiliation)
    end
  end

  describe '#partner' do
    it 'fetches partner for donor' do
      expect(Partners::GetPartnerForDonor).to receive(:call).with(donor:).and_return(partner)
      expect(controller.send(:partner)).to eq(partner)
    end
  end

  describe '#managed_portfolio?' do
    it 'returns true when portfolio has a manager' do
      portfolio_manager = double('portfolio_manager')
      allow(controller).to receive(:active_portfolio).and_return(portfolio)
      allow(Portfolios::GetPortfolioManager).to receive(:call).with(portfolio:).and_return(portfolio_manager)
      expect(controller.send(:managed_portfolio?)).to be true
    end

    it 'returns false when portfolio has no manager' do
      allow(controller).to receive(:active_portfolio).and_return(portfolio)
      allow(Portfolios::GetPortfolioManager).to receive(:call).with(portfolio:).and_return(nil)
      expect(controller.send(:managed_portfolio?)).to be false
    end
  end

  describe '#selectable_portfolios' do
    it 'includes active portfolio when not managed' do
      allow(controller).to receive(:active_portfolio).and_return(portfolio)
      allow(controller).to receive(:managed_portfolio?).and_return(false)
      allow(Partners::GetManagedPortfoliosForPartner).to receive(:call).with(partner:).and_return([])

      result = controller.send(:selectable_portfolios)
      expect(result).to include([portfolio.id, 'My personalized portfolio'])
    end

    it 'includes managed portfolios from partner' do
      allow(controller).to receive(:active_portfolio).and_return(portfolio)
      allow(controller).to receive(:managed_portfolio?).and_return(true)

      managed_portfolios_result = double('ManagedPortfoliosResult')
      allow(managed_portfolios_result).to receive(:pluck).with(:portfolio_id,
                                                               :name).and_return([['managed_id', 'Managed Portfolio']])

      allow(Partners::GetManagedPortfoliosForPartner).to receive(:call).with(partner:)
                                                                       .and_return(managed_portfolios_result)

      result = controller.send(:selectable_portfolios)
      expect(result).to include(['managed_id', 'Managed Portfolio'])
    end
  end

  describe '#new_subscription' do
    it 'builds a new subscription with correct attributes' do
      allow(controller).to receive(:active_portfolio).and_return(portfolio)
      allow(controller).to receive(:target_amount_cents).and_return(5000)

      result = controller.send(:new_subscription)
      expect(result).to be_a(Subscription)
      expect(result.donor).to eq(donor)
      expect(result.amount_cents).to eq(5000)
      expect(result.portfolio).to eq(portfolio)
      expect(result.frequency).to eq(donor.contribution_frequency)
    end
  end

  describe '#target_amount_cents' do
    it 'gets target contribution amount cents' do
      expect(Contributions::GetTargetContributionAmountCents).to receive(:call).with(
        donor:, frequency: subscription.frequency
      ).and_return(5000)

      expect(controller.send(:target_amount_cents)).to eq(5000)
    end
  end

  describe '#amount_cents' do
    it 'converts amount_dollars to cents' do
      expect(controller.send(:amount_cents)).to eq(5000)
    end
  end

  describe '#tips_cents' do
    it 'gets tips_cents from params' do
      expect(controller.send(:tips_cents)).to eq(200)
    end
  end

  describe '#amount_dollars' do
    it 'gets amount_dollars from params' do
      expect(controller.send(:amount_dollars)).to eq(50)
    end
  end

  describe '#trial_amount_cents' do
    it 'converts trial_amount_dollars to cents' do
      expect(controller.send(:trial_amount_cents)).to eq(1000)
    end
  end

  describe '#trial_amount_dollars' do
    it 'gets trial_amount_dollars from params' do
      expect(controller.send(:trial_amount_dollars)).to eq(10)
    end
  end

  describe '#payment_token' do
    it 'gets payment_token from params' do
      expect(controller.send(:payment_token)).to eq('test_token')
    end
  end

  describe '#frequency' do
    it 'gets frequency from params' do
      expect(controller.send(:frequency)).to eq('monthly')
    end
  end

  describe '#portfolio_id' do
    it 'gets portfolio_id from params' do
      expect(controller.send(:portfolio_id)).to eq(portfolio.id)
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
  end
end
