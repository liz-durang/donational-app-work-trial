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

require 'rails_helper'

RSpec.describe Campaign, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
