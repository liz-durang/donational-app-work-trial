# frozen_string_literal: true

# == Schema Information
#
# Table name: grants
#
#  id               :uuid             not null, primary key
#  organization_ein :string
#  amount_cents     :integer
#  receipt          :json
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  scheduled_at     :datetime
#  processed_at     :datetime
#  voided_at        :datetime
#

# Funds distributed from Donational to an Organization
class Grant < ApplicationRecord
  belongs_to :organization, foreign_key: 'organization_ein'
  has_many :donations

  monetize :amount_cents

  def to_param
    short_id
  end

  def short_id
    id[0...6]
  end
end
