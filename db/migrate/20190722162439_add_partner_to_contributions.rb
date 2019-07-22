class AddPartnerToContributions < ActiveRecord::Migration[5.2]
  def change
    add_reference :contributions, :partner, type: :uuid, foreign_key: true
    add_reference :recurring_contributions, :partner, type: :uuid, foreign_key: true
  end
end
