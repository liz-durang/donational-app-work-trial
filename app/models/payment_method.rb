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

class PaymentMethod < ApplicationRecord
  belongs_to :donor

  def retry_count_limit_reached?
    retry_count == 3
  end

  def payment_type
    type.demodulize
  end
end

module PaymentMethods
  class Card < PaymentMethod; end
  class BankAccount < PaymentMethod; end
  class AcssDebit < PaymentMethod; end
end
