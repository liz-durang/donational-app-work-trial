class ProfileContribution
  include ActiveModel::Model

  attr_accessor :first_name,
                :last_name,
                :email,
                :amount_dollars,
                :frequency,
                :start_at,
                :portfolio_id
end
