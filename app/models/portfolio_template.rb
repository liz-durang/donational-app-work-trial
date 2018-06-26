class PortfolioTemplate < ApplicationRecord
  belongs_to :partner

  def size
    organization_eins.count
  end
end
