# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_methods
#
#  id                            :uuid             not null, primary key
#  donor_id                      :uuid             not null
#  payment_processor_customer_id :string
#  name                          :string
#  last4                         :string
#  deactivated_at                :datetime
#  address_zip_code              :string
#  retry_count                   :integer          default(0)
#  type                          :string           default("PaymentMethods::Card")
#  institution                   :string
#

FactoryBot.define do
  factory :payment_method, class: 'PaymentMethods::Card' do
    donor
    last4 { '1234' }
    type { 'PaymentMethods::Card' }

    factory :acss_debit_payment_method, class: 'PaymentMethods::AcssDebit' do
      type { 'PaymentMethods::AcssDebit' }
    end

    factory :us_bank_account_payment_method, class: 'PaymentMethods::BankAccount' do
      type { 'PaymentMethods::BankAccount' }
    end

    factory :bacs_debit_payment_method, class: 'PaymentMethods::BacsDebit' do
      type { 'PaymentMethods::BacsDebit' }
    end
  end
end
