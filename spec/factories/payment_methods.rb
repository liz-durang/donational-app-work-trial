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
  factory :payment_method do
    donor
    last4 { '1234' }

    trait :acss_debit do
      type { 'PaymentMethods::AcssDebit' }
      payment_processor_source_id { 'pm_1KEYLlLVTYFX0Htp1vL4L722' }
    end
  end
end
