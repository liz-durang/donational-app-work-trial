class AddDonorToContributions < ActiveRecord::Migration[5.1]
  def up
    add_reference :contributions, :donor, type: :uuid, foreign_key: true

    assume_existing_contributions_were_made_by_the_portfolio_owner!
  end

  private

  def assume_existing_contributions_were_made_by_the_portfolio_owner!
    Contribution.reset_column_information
    Contribution.all.each do |c|
      c.update(donor: c.portfolio.donor)
    end
  end
end
