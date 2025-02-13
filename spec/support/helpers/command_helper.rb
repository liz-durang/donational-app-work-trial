module Helpers
  module CommandHelper
    def successful_outcome
      double(success?: true)
    end

    def failure_outcome
      allow_any_instance_of(Mutations::Outcome).to receive(:errors).and_return(double(message_list: ['Error message']))

      double(
        success?: false, 
        errors: double(
          message_list: ['Error message'], 
          any?: true, 
          to_hash: { message_list: ['Error message'] }
        )
      )
    end
  end
end
