class SelectedPortfolio < ApplicationRecord
  belongs_to :donor
  belongs_to :portfolio

  def active?
    deactivated_at.nil?
  end
end
