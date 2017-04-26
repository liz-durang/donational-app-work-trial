class Organization < ApplicationRecord
  self.primary_key = 'ein'

  validates :ein, presence: true
  validates :name, presence: true
end
