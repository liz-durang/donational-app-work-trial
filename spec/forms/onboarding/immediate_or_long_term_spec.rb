require 'rails_helper'

RSpec.describe Onboarding::ImmediateOrLongTerm, type: :model do
  subject(:step) { Onboarding::ImmediateOrLongTerm.new(donor) }

  let(:donor) { instance_double(Donor, id: 'donor-uuid') }

  describe '#process!' do
    context "when the response is 'immediate'" do
      it "sets the Donor's preferences to immediate impact organizations only" do
        expect(Donors::UpdateDonor).to receive(:run!).with(
          donor: donor,
          include_immediate_impact_organizations: true,
          include_long_term_impact_organizations: false
        )

        step.process!('immediate')
      end
    end

    context "when the response is 'both'" do
      it "sets the Donor's preferences to immediate impact and long term impact organizations" do
        expect(Donors::UpdateDonor).to receive(:run!).with(
          donor: donor,
          include_immediate_impact_organizations: true,
          include_long_term_impact_organizations: true
        )

        step.process!('both')
      end
    end

    context "when the response is 'long_term'" do
      it "sets the Donor's preferences to long term impact organizations only" do
        expect(Donors::UpdateDonor).to receive(:run!).with(
          donor: donor,
          include_immediate_impact_organizations: false,
          include_long_term_impact_organizations: true
        )

        step.process!('long_term')
      end
    end

    context "when the response is something else" do
      it "adds errors to the form" do
        step.process!(123)

        expect(step.errors.messages[:response]).to include('123 is not one of the allowed responses')
      end

      it "doesn't touch the Donor" do
        expect(Donors::UpdateDonor).not_to receive(:run!)

        step.process!(true)
      end
    end
  end
end
