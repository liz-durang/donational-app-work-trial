# == Schema Information
#
# Table name: portfolio_templates
#
#  id                :uuid             not null, primary key
#  partner_id        :uuid
#  title             :string
#  organization_eins :string           is an Array
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class PortfolioTemplate < ApplicationRecord
  belongs_to :partner

  def size
    organization_eins.count
  end
end
