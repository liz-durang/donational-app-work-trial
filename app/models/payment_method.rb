# == Schema Information
#
# Table name: payment_methods
#
#  id                            :uuid             not null, primary key
#  donor_id                      :uuid             not null
#  payment_processor_customer_id :string
#  name_on_card                  :string
#  last4                         :string
#  deactivated_at                :datetime
#

class PaymentMethod < ApplicationRecord
  belongs_to :donor
end
