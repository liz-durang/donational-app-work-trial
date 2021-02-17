# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contributions::RefundContribution do
  include ActiveSupport::Testing::TimeHelpers

  context 'when the contribution has been processed' do
    let(:donor) do
      create(:donor, email: 'user@example.com')
    end

    let(:contribution) do
      create(
        :contribution,
        donor: donor,
        receipt: {
          "id" => "126534162",
          "object" => "charge"
        }
      )
    end

    let(:metadata) do
      {
        donor_id: donor.id,
        contribution_id: contribution.id
      }
    end

    context 'and the refund succeeds' do
      before do
        allow(Payments::GetPaymentProcessorAccountId)
          .to receive(:call)
          .with(donor: donor)
          .and_return('acc_123')
      end

      it 'refunds the contribution and deletes the donations' do
        expect(Payments::RefundCharge).to receive(:run).with(
          account_id: 'acc_123',
          charge_id: '126534162',
          metadata: metadata
        ).and_return(double(success?: true))

        expect(Donations::DeleteDonationsForContribution).to receive(:run).with(
          contribution: contribution
        ).and_return(double(success?: true))

        command = described_class.run(contribution: contribution)

        expect(command).to be_success
        expect(contribution.refunded_at.present?)
        expect(contribution.payment_status).to eq 'refunded'
      end
    end

    context 'and the refund fails' do
      before do
        allow(Payments::GetPaymentProcessorAccountId)
          .to receive(:call)
          .with(donor: donor)
          .and_return('acc_123')

        allow(Payments::RefundCharge)
          .to receive(:run)
          .with(
            account_id: 'acc_123',
            charge_id: '126534162',
            metadata: metadata
          ).and_return(double(success?: false, errors: { some: 'error' }))
      end

      it 'does not refund the contribution' do
        command = described_class.run(contribution: contribution)

        expect(command).not_to be_success
        expect(!contribution.refunded_at.present?)
      end
    end
  end
end
