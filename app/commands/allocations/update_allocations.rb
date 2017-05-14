module Allocations
  class UpdateAllocations < Mutations::Command
    required do
      model :subscription
      array :allocations do
        hash do
          required do
            string :organization_ein
            integer :percentage
          end
        end
      end
    end

    def validate
      ensure_allocations_add_to_one_hundred_percent!
    end

    def execute
      Allocation.transaction do
        deactivate_existing_allocations!

        allocations.each do |allocation|
          Allocation.create!(
            subscription: subscription,
            organization_ein: allocation[:organization_ein],
            percentage: allocation[:percentage]
          )
        end
      end
      nil
    end

    private

    def deactivate_existing_allocations!
      Allocations::GetActiveAllocations.call(subscription: subscription)
                                       .update_all(deactivated_at: Time.zone.now)
    end

    def ensure_allocations_add_to_one_hundred_percent!
      return if allocations.sum { |h| h[:percentage] } == 100

      add_error(
        :allocations,
        :add_up_to_one_hundred_percent,
        'Allocations must add up to 100 percent'
      )
    end
  end
end
