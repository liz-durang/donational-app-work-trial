require 'stripe'

module Payments
  class GenerateAcssClientSecretForDonor < ApplicationQuery
    attr_reader :donor

    def call(donor:)
      @donor = donor

      set_interval
      create_stripe_setup_intent

      return client_secret, customer_id
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      Rails.logger.error(e)
      nil
    end

    protected

    def create_stripe_setup_intent
      @setup_intent = Stripe::SetupIntent.create(
        {
          payment_method_types: ['acss_debit'],
          customer: customer_id,
          payment_method_options: {
            acss_debit: {
              currency: 'cad',
              mandate_options: {
                payment_schedule: 'interval',
                interval_description: @interval_description,
                transaction_type: 'personal'
              },
            }
          }
        },
        { stripe_account: account_id }
      )
    end

    def customer_id
      customer[:id]
    end

    def account_id
      @account_id ||= Payments::GetPaymentProcessorAccountId.call(donor: donor)
    end

    def customer
      @customer ||= (customer_by_id || create_customer)
    end

    def customer_by_id
      return nil unless payment_method.present?
      return nil if payment_method.payment_processor_customer_id.blank?

      outcome = Payments::FindCustomerById.run(
        customer_id: payment_method.payment_processor_customer_id,
        account_id: account_id
      )
      return nil unless outcome.success?

      outcome.result
    end

    def payment_method
      @payment_method ||= Payments::GetActivePaymentMethod.call(donor: donor)
    end

    def create_customer
      Stripe::Customer.create({}, { stripe_account: account_id })
    end

    def subscription
      @subscription = Contributions::GetActiveSubscription.call(donor: donor)
    end

    def set_interval
      month, year = month_and_year(subscription.start_at)

      @interval_description = if subscription.frequency == "once"
        "one time charge"
      elsif subscription.trial_start_at
        month, year = month_and_year
        "on the 15th of every month, starting #{month} #{year}"
      elsif subscription.frequency == "monthly"
        month, year = month_and_year if subscription.start_at < Date.today
        "on the 15th of every month, starting #{month} #{year}"
      elsif subscription.frequency == "quarterly"
        "every three months, starting #{month} #{year}"
      elsif subscription.frequency == "yearly"
        "once a year, starting #{month} #{year}"
      else
        "on the 15th of every month"
      end
    end

    def client_secret
      @setup_intent[:client_secret]
    end

    # Returns ["Dec", 2021]
    def month_and_year(date = Date.today)
      return date.strftime("%b"), date.year
    end
  end
end
