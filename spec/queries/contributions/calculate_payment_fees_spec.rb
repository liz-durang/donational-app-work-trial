require 'rails_helper'

RSpec.describe Contributions::CalculatePaymentFees do
  subject { Contributions::CalculatePaymentFees.call(contribution: contribution) }

  let(:donor) { build(:donor) }
  let(:contribution) do
    build(:contribution,
      donor: donor,
      amount_cents: 100 * 100,
      tips_cents: 5 * 100
    )
  end

  before do
    allow(Partners::GetPartnerForDonor).to receive(:call).with(donor: donor).and_return(partner)
  end

  context 'when the donor is affiliated with a partner' do
    let(:partner) { build(:partner, platform_fee_percentage: 0.02 ) }

    it 'calculates the platform fee based on the amount (excluding tips)' do
      expect(subject.platform_fee_cents).to eq 200
    end

    it 'calculates the payment fees' do
      expect(subject.to_h).to eq ({
        amount_cents: 100_00,
        tips_cents: 5_00,
        total_charge_amount_cents: 105_00, # ($100 + $5 tip)
        platform_fee_cents: 2_00, # ($100 * 2%)
        payment_processor_fees_cents: 335, # ($105 * 2.9% + $0.30)
        donor_advised_fund_fees_cents: 100, # ($100 * 1%)
        amount_donated_after_fees_cents: 9365 # ($100 - $2 platform fee - $3.34 payment fee - $1 DAF fee)
      })
    end
  end

  context 'when the donor is not affiliated with a partner' do
    let(:partner) { nil }

    it 'does not charge a platform_fee' do
      expect(subject.platform_fee_cents).to eq 0
    end

    it 'calculates the payment fees' do
      expect(subject.to_h).to eq ({
        amount_cents: 100_00,
        tips_cents: 5_00,
        total_charge_amount_cents: 105_00, # ($100 + $5 tip)
        platform_fee_cents: 0, # ($100 * 0%)
        payment_processor_fees_cents: 335, # ($105 * 2.9% + $0.30)
        donor_advised_fund_fees_cents: 100, # ($100 * 1%)
        amount_donated_after_fees_cents: 9565 # ($100 - $0 platform fee - $3.34 payment fee - $1 DAF fee)
      })
    end
  end


end
