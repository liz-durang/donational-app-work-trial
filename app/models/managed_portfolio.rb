class ManagedPortfolio < ApplicationRecord
  belongs_to :partner
  belongs_to :portfolio

  delegate :size, to: :portfolio
  def available_to_new_donors?
    hidden_at.blank?
  end
end
