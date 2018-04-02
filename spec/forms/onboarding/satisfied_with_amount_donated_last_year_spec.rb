require 'rails_helper'

RSpec.describe Onboarding::SatisfiedWithAmountDonatedLastYear, type: :model do
  subject(:step) { Onboarding::SatisfiedWithAmountDonatedLastYear.new(donor) }

  let(:donor) { instance_double(Donor, id: 'donor-uuid') }

  describe '#process!' do
    context "when the response is 'satisfied'" do
      it "sets the Donor's #satisfaction_with_prior_donation to satisfied" do
        expect(Donors::UpdateDonor)
          .to receive(:run!)
          .with(donor: donor, satisfaction_with_prior_donation: :satisfied)

        step.process!('satisfied')
      end
    end

    context "when the response is 'gave_too_much'" do
      it "sets the Donor's #satisfaction_with_prior_donation to gave_too_much" do
        expect(Donors::UpdateDonor)
          .to receive(:run!)
          .with(donor: donor, satisfaction_with_prior_donation: :gave_too_much)

        step.process!('gave_too_much')
      end
    end

    context "when the response is 'did_not_give_enough'" do
      it "sets the Donor's #satisfaction_with_prior_donation to did_not_give_enough" do
        expect(Donors::UpdateDonor)
          .to receive(:run!)
          .with(donor: donor, satisfaction_with_prior_donation: :did_not_give_enough)

        step.process!('did_not_give_enough')
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
