# == Schema Information
#
# Table name: managed_portfolios
#
#  id           :uuid             not null, primary key
#  partner_id   :uuid
#  portfolio_id :uuid
#  name         :string
#  description  :text
#  hidden_at    :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'rails_helper'

RSpec.describe ManagedPortfolio, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
