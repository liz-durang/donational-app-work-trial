class PayIn < ApplicationRecord
  belongs_to :subscription
  has_one :donor, through: :subscription
  has_many :donations
end
