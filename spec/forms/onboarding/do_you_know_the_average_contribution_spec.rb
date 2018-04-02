require 'rails_helper'

RSpec.describe Onboarding::DoYouKnowTheAverageContribution, type: :model do
  subject(:step) { Onboarding::DoYouKnowTheAverageContribution.new(donor) }

  let(:donor) { instance_double(Donor, id: 'donor-uuid') }

  describe '#process!' do
    context "when the response is 'yes'" do
      it "sets the Donor's #surprised_by_average_american_donation_rate to yes" do
        expect(Donors::UpdateDonor)
          .to receive(:run!)
          .with(donor: donor, surprised_by_average_american_donation_rate: :yes)


        step.process!('yes')
      end
    end

    context "when the response is 'somewhat'" do
      it "sets the Donor's #surprised_by_average_american_donation_rate to somewhat" do
        expect(Donors::UpdateDonor)
          .to receive(:run!)
          .with(donor: donor, surprised_by_average_american_donation_rate: :somewhat)

        step.process!('somewhat')
      end
    end

    context "when the response is 'no'" do
      it "sets the Donor's #surprised_by_average_american_donation_rate to no" do
        expect(Donors::UpdateDonor)
          .to receive(:run!)
          .with(donor: donor, surprised_by_average_american_donation_rate: :no)

        step.process!('no')
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
