# == Schema Information
#
# Table name: campaigns
#
#  id                            :uuid             not null, primary key
#  partner_id                    :uuid
#  title                         :string
#  description                   :text
#  slug                          :string
#  target_amount_cents           :integer
#  default_contribution_amounts  :string           is an Array
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  contribution_amount_help_text :string
#  allow_one_time_contributions  :boolean          default(TRUE), not null
#

class Campaign < ApplicationRecord
  belongs_to :partner
  has_one_attached :banner_image

  validates :slug, uniqueness: true

  def allowable_donation_frequencies
    if allow_one_time_contributions?
      RecurringContribution.frequency.options.select { |k,v| v.in? ['once', 'monthly'] } 
    else
      RecurringContribution.frequency.options.select { |k,v| v == 'monthly' }
    end
  end
end
