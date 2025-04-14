require 'rails_helper'

RSpec.describe SendContributionReminders, type: :job do
  let(:subscription1) { double('Subscription', donor: donor1, update!: true) }
  let(:subscription2) { double('Subscription', donor: donor2, update!: true) }
  let(:donor1) { double('Donor') }
  let(:donor2) { double('Donor') }
  let(:payment_method1) { double('PaymentMethod') }
  let(:payment_method2) { double('PaymentMethod') }
  let(:partner1) { double('Partner') }
  let(:partner2) { double('Partner') }
  let(:remindable_subscriptions) { [subscription1, subscription2] }

  before do
    allow(Contributions::GetSubscriptionsWhichNeedReminder).to receive(:call).and_return(remindable_subscriptions)
    allow(Payments::GetActivePaymentMethod).to receive(:call).with(donor: donor1).and_return(payment_method1)
    allow(Payments::GetActivePaymentMethod).to receive(:call).with(donor: donor2).and_return(payment_method2)
    allow(Partners::GetPartnerForDonor).to receive(:call).with(donor: donor1).and_return(partner1)
    allow(Partners::GetPartnerForDonor).to receive(:call).with(donor: donor2).and_return(partner2)
    allow(RemindersMailer).to receive_message_chain(:send_reminder, :deliver_now)
  end

  it 'sends reminders for each remindable subscription' do
    expect(RemindersMailer).to receive(:send_reminder).with(subscription1, payment_method1, partner1).and_return(double(deliver_now: true))
    expect(RemindersMailer).to receive(:send_reminder).with(subscription2, payment_method2, partner2).and_return(double(deliver_now: true))

    described_class.perform_inline
  end

  it 'updates the last_reminded_at timestamp for each subscription' do
    expect(subscription1).to receive(:update!).with(last_reminded_at: kind_of(ActiveSupport::TimeWithZone))
    expect(subscription2).to receive(:update!).with(last_reminded_at: kind_of(ActiveSupport::TimeWithZone))

    described_class.perform_inline
  end
end
