require 'rails_helper'

RSpec.describe Onboarding::WhatIsYourPreTaxIncome, type: :model do
  subject(:step) { Onboarding::WhatIsYourPreTaxIncome.new(donor) }

  let(:donor) { instance_double(Donor, id: 'donor-uuid') }

  describe '#process!' do
    context "when the response is a formatted number of annual income" do
      let(:response) { '$76,543.21' }

      it "sets the Donor's #annual_income_cents" do
        expect(Donors::UpdateDonor)
          .to receive(:run!)
          .with(donor: donor, annual_income_cents: 76_543_21)

        step.process!(response)
      end
    end

    context "when the response is negative" do
      let(:response) { '-$50,000' }

      it "adds errors to the form" do
        step.process!(response)

        expect(step.errors.messages[:response])
          .to include('must be greater than or equal to 0')
      end

      it "doesn't touch the Donor" do
        expect(donor).not_to receive(:update)

        step.process!(response)
      end
    end
  end
end
