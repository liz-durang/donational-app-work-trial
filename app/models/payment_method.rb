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
#  address_zip_code              :string
#  retry_count                   :integer          default(0)
#

class PaymentMethod < ApplicationRecord
  belongs_to :donor

  def retry_count_limit_reached?
    retry_count == 3
  end
end
