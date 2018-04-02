require 'rails_helper'

RSpec.describe Onboarding::HowMuchShouldAnIndividualGive, type: :model do
  subject(:step) { Onboarding::HowMuchShouldAnIndividualGive.new(donor) }

  let(:donor) { instance_double(Donor, id: 'donor-uuid') }

  describe '#process!' do
    context "when the response is one of the allowed responses" do
      let(:response) { 0.035 }

      it "sets the Donor's #donation_rate_expected_from_individuals" do
        expect(Donors::UpdateDonor)
          .to receive(:run!)
          .with(donor: donor, donation_rate_expected_from_individuals: 0.035)

        step.process!(response)
      end
    end

    context "when the response is not one of the allowed responses" do
      it "adds errors to the form" do
        step.process!(123)

        expect(step.errors.messages[:response])
          .to include('123.0 is not one of the allowed responses')
      end

      it "doesn't touch the Donor" do
        expect(Donors::UpdateDonor).not_to receive(:run!)

        step.process!(-0.01)
      end
    end
  end
end
