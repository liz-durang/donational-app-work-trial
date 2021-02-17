namespace :contributions do
  desc 'Update payment_methods#payment_processor_source_id'
  task :update_amount_donated_after_fees_cents => [:environment] do
    puts 'Started updating amount donated after fees cents for contributions'

    processed_contributions = Contribution
                                .where.not(processed_at: nil)
                                .where(amount_donated_after_fees_cents: nil)

    if processed_contributions.count.zero?
      puts 'All processed contributions have amount donated after fees cents set'

      exit
    end

    processed_contributions.each do |contribution|
      payment_fees = Contributions::CalculatePaymentFees.call(contribution: contribution)
      contribution.update_column(:amount_donated_after_fees_cents, payment_fees.amount_donated_after_fees_cents)

      print '.'
    end

    puts 'Completed updating amount donated after fees cents for contributions'
  end
end
