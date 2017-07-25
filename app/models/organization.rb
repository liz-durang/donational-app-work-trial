# == Schema Information
#
# Table name: organizations
#
#  ein              :string           not null, primary key
#  name             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  local_impact     :boolean
#  global_impact    :boolean
#  immediate_impact :boolean
#  long_term_impact :boolean
#

# A charity of non-profit organization
class Organization < ApplicationRecord
  self.primary_key = 'ein'

  has_many :pay_outs, foreign_key: 'organization_ein'
  has_many :donations

  validates :ein, presence: true
  validates :name, presence: true
end
