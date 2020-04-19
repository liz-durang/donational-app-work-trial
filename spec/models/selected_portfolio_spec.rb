# == Schema Information
#
# Table name: selected_portfolios
#
#  id             :bigint           not null, primary key
#  donor_id       :uuid
#  portfolio_id   :uuid
#  deactivated_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'rails_helper'

RSpec.describe SelectedPortfolio, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
