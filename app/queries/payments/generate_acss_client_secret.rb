require 'stripe'

module Payments
  class GenerateAcssClientSecret < ApplicationQuery
    def call(account_id:, email:, frequency:, start_at_month:, start_at_year:, trial:)
      @account_id = account_id

      set_interval(frequency, start_at_month, start_at_year, trial)
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
        { stripe_account: @account_id }
      )
    end

    def set_interval(frequency, start_at_month, start_at_year, trial)
      @interval_description = if frequency == "once"
        "one time charge, within the next 30 days"
      elsif trial
        today = Date.today
        month = today.strftime("%b")
        year = today.year
        "on the 15th of every month, starting #{month} #{year}"
      elsif frequency == "monthly"
        "on the 15th of every month, starting #{start_at_month} #{start_at_year}"
      elsif frequency == "quarterly"
        "every three months, starting #{start_at_month} #{start_at_year}"
      elsif frequency == "yearly"
        "once a year, starting #{start_at_month} #{start_at_year}"
      else
        "on the 15th of every month"
      end
    end

    def client_secret
      @setup_intent[:client_secret]
    end

    def customer_id
      @customer_id ||= begin
        customer = Stripe::Customer.create({}, { stripe_account: @account_id })
        customer[:id]
      end
    end
  end
end
