module Allocations
  class UpdateAllocations < ApplicationCommand
    required do
      model :portfolio
      array :allocations do
        hash do
          required do
            string :organization_ein
            string :percentage
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
          next unless allocation[:percentage].to_i > 0

          Allocation.create!(
            portfolio: portfolio,
            organization_ein: allocation[:organization_ein],
            percentage: allocation[:percentage].to_i
          )
        end
      end
      nil
    end

    private

    def deactivate_existing_allocations!
      GetActiveAllocations.call(portfolio: portfolio)
                          .update_all(deactivated_at: Time.zone.now)
    end

    def ensure_allocations_add_to_one_hundred_percent!
      return if allocations.sum { |h| h[:percentage].to_i } == 100

      add_error(
        :allocations,
        :add_up_to_one_hundred_percent,
        'Allocations must add up to 100 percent'
      )
    end
  end
end
