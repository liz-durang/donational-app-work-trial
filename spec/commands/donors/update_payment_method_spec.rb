require 'rails_helper'

RSpec.describe Donors::UpdatePaymentMethod do
  around do |example|
    ClimateControl.modify(PANDAPAY_SECRET_KEY: 'sk_test_123') do
      example.run
    end
  end

  let(:donor) { Donor.create(email: 'donor@example.com', payment_processor_customer_id: customer_id) }

  context 'when the donor can be found by customer id' do
    let(:customer_id) { 'cus_123' }
    let(:existing_customer) { { id: 'cus_123' } }

    before do
      allow(Payments::FindCustomerById)
        .to receive(:run)
        .with(customer_id: 'cus_123')
        .and_return(double(success?: true, result: existing_customer))

      allow(Donors::UpdateDonor).to receive(:run).and_return(double(success?: true))
    end

    context "and the update to the customer's card succeeds" do
      let(:successful_update) { double(success?: true) }

      it 'updates the card for the existing customer' do
        expect(Payments::UpdateCustomerCard)
          .to receive(:run)
          .with(customer_id: 'cus_123', payment_token: 'token')
          .and_return(successful_update)

        command = Donors::UpdatePaymentMethod.run(donor: donor, payment_token: 'token')

        expect(command).to be_success
      end
    end

    context "and the update to the customer's card fails" do
      let(:failed_update) { double(success?: false, errors: update_errors) }

      let(:update_errors) do
        errors = Mutations::ErrorHash.new
        errors[:foo] = Mutations::ErrorAtom.new(:foo, :is_error)
        errors[:bar] = Mutations::ErrorAtom.new(:bar, :is_another_error)
        errors
      end

      it 'fails with the errors from the update command' do
        expect(Payments::UpdateCustomerCard)
          .to receive(:run)
          .and_return(failed_update)

        command = Donors::UpdatePaymentMethod.run(donor: donor, payment_token: 'token')

        expect(command).not_to be_success
        expect(command.errors).to eq update_errors
      end
    end
  end

  context 'when the donor does not have a customer id' do
    let(:customer_id) { '' }

    context 'and the customer can be created' do
      let(:successful_create) { double(success?: true, result: { id: 'new_cus_123' }) }
      let(:successful_update) { double(success?: true) }

      before do
        expect(Payments::CreateCustomer)
          .to receive(:run)
          .with(email: 'donor@example.com')
          .and_return(successful_create)

        allow(Payments::UpdateCustomerCard).to receive(:run).and_return(double(success?: true))
      end

      it 'saves the newly created customer id to the donor' do
        expect(Donors::UpdateDonor)
          .to receive(:run)
          .with(donor: donor, payment_processor_customer_id: 'new_cus_123')
          .and_return(successful_update)

        command = Donors::UpdatePaymentMethod.run(donor: donor, payment_token: 'token')

        expect(command).to be_success
      end

      context "and the update to the customer's card succeeds" do
        let(:successful_update) { double(success?: true) }

        it 'updates the card for the existing customer' do
          expect(Payments::UpdateCustomerCard)
            .to receive(:run)
            .with(customer_id: 'new_cus_123', payment_token: 'token')
            .and_return(successful_update)

          command = Donors::UpdatePaymentMethod.run(donor: donor, payment_token: 'token')

          expect(command).to be_success
        end
      end
    end

    context 'and the customer cannot be created' do
      before do
        expect(Payments::CreateCustomer)
          .to receive(:run)
          .with(email: 'donor@example.com')
          .and_return(double(success?: false))

        allow(Payments::UpdateCustomerCard).to receive(:run).and_return(double(success?: true))
      end

      context 'and there is an existing customer with a matching email' do
        let(:existing_customer) { { id: 'cus_with_matching_email' } }
        let(:successful_update) { double(success?: true) }

        before do
          expect(Payments::FindCustomerByEmail)
            .to receive(:run)
            .with(email: 'donor@example.com')
            .and_return(double(success?: true, result: existing_customer))
        end

        it 'saves the matching customer id to the donor' do
          expect(Donors::UpdateDonor)
            .to receive(:run)
            .with(donor: donor, payment_processor_customer_id: 'cus_with_matching_email')
            .and_return(successful_update)

          command = Donors::UpdatePaymentMethod.run(donor: donor, payment_token: 'token')

          expect(command).to be_success
        end

        context "and the update to the customer's card succeeds" do
          let(:successful_update) { double(success?: true) }

          it 'updates the card for the existing customer' do
            expect(Payments::UpdateCustomerCard)
              .to receive(:run)
              .with(customer_id: 'cus_with_matching_email', payment_token: 'token')
              .and_return(successful_update)

            command = Donors::UpdatePaymentMethod.run(donor: donor, payment_token: 'token')

            expect(command).to be_success
          end
        end
      end

      context 'and there are no existing customers with matching emails' do
        before do
          expect(Payments::FindCustomerByEmail)
            .to receive(:run)
            .with(email: 'donor@example.com')
            .and_return(double(success?: false))
        end

        it 'fails with customer not found errors' do
          expect(Donors::UpdateDonor).not_to receive(:run)

          command = Donors::UpdatePaymentMethod.run(donor: donor, payment_token: 'token')

          expect(command).not_to be_success
          expect(command.errors.symbolic).to include(customer: :empty)
        end
      end
    end
  end

  context 'when a payment token is not supplied' do
    let(:payment_token) { '' }
    let(:customer_id) { 'cus_123' }

    it 'fails with errors' do
      expect(Payments::FindCustomerById).not_to receive(:run)
      expect(Payments::FindCustomerByEmail).not_to receive(:run)
      expect(Payments::CreateCustomer).not_to receive(:run)

      command = Donors::UpdatePaymentMethod.run(donor: donor, payment_token: payment_token)

      expect(command).not_to be_success
      expect(command.errors.symbolic).to include(payment_token: :empty)
    end
  end
end
