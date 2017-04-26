class PayIn < ApplicationRecord
  belongs_to :subscription
  has_one :donor, through: :subscription
end
