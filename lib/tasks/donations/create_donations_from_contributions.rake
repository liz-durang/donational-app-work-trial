namespace :donations do
  desc 'Create donations from contributions'
  task :create_donations_from_contributions => [:environment] do
    puts 'Started creating donations from contributions'

    created_from = (Date.today - 1.year).beginning_of_year.beginning_of_day

    contribution_ids_without_donations = Contribution
                                          .where(payment_status: :succeeded)
                                          .where('contributions.created_at >= ?', created_from)
                                          .left_joins(:donations)
                                          .group('contributions.id')
                                          .having('count(donations.id) = 0')
                                          .pluck(:id)

    contributions_without_donations = Contribution.where(id: contribution_ids_without_donations)
    
    if contributions_without_donations.count.zero?
      puts 'All succeeded contributions have the donations for each charity created'

      exit
    end

    contributions_without_donations.each do |contribution|
      outcome = Donations::CreateDonationsFromContributionIntoPortfolio.run(
        contribution: contribution,
        donation_amount_cents: contribution.amount_donated_after_fees_cents
      )

      if outcome.success?
        puts "Created #{contribution.donations.count} donations for contribution #{contribution.id}"
      else
        errors = outcome.errors.message_list.join('. ')
        puts "Could not create donations for contribution #{contribution.id}. Errors: #{errors}"
      end
    end

    puts 'Completed creating donations from contributions'
  end
end
