# == Schema Information
#
# Table name: organizations
#
#  ein        :string           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Organization < ApplicationRecord
  self.primary_key = 'ein'

  has_many :pay_outs, foreign_key: 'organization_ein'
  has_many :donations

  validates :ein, presence: true
  validates :name, presence: true
end
