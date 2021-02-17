module Partners
  class PaymentMethodsController < ApplicationController
    include Secured

    def create
      outcome = Payments::UpdatePaymentMethod.run(
        donor: donor,
        payment_token: params[:payment_token],
        payment_method_id: params[:payment_method_id]
      )

      flash[:success] = "Thanks, we've updated this donor's payment information" if outcome.success?
      flash[:error] = outcome.errors.message_list.join('\n') unless outcome.success?
      redirect_to edit_partner_donor_path(partner, donor)
    end

    private

    def partner
      @partner = Partners::GetPartnerById.call(id: params[:partner_id])
    end

    def donor
      @donor = Donors::GetDonorById.call(id: params[:id])
    end
  end
end
