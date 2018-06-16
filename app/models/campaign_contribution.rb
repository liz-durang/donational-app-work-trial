class CampaignContribution
  include ActiveModel::Model

  attr_accessor :first_name, :last_name, :email, :amount_dollars, :payment_token, :frequency
end
