require 'stripe'

namespace :payments do
  desc 'Update payment_methods#payment_processor_source_id'
  task :update_payment_methods_source_id => [:environment] do
    puts 'Started updating payment processor source IDs'

    active_payment_methods_without_source_id = PaymentMethod
                                                .where(deactivated_at: nil)
                                                .where(payment_processor_source_id: nil)

    if active_payment_methods_without_source_id.count.zero?
      puts 'All active payment methods have the corresponding payment processor source ID'

      exit
    end

    Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')

    active_payment_methods_without_source_id.each do |payment_method|
      sources = Stripe::Customer.list_sources(payment_method.payment_processor_customer_id)

      if sources[:data].count.zero?
        puts "Could not find a source for customer: #{payment_method.payment_processor_customer_id}"

        next
      end

      payment_method.update_column(:payment_processor_source_id, sources[:data][0][:id])
      print "."
    end

    puts 'Completed updating payment processor source IDs'
  end
end
