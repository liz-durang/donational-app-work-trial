module Api
  module V1
    class DonorsController < Api::V1::ApiController
      def create
        outcome = Donors::CreateDonorAffiliatedWithPartner.run(donor_params.merge(partner: current_partner))

        unless outcome.success?
          render_errors(outcome.errors.message, :bad_request)
        end

        @donor = outcome.result
      end

      def index
        @donors = Donors::GetDonorsByEmail.call(email: search_params)
        @donors = @donors.select { |donor| donor_is_affiliated_to_current_partner(donor) } if @donors.present?
      end

      def show
        @donor = Donors::GetDonorById.call(id: params[:id])

        unless donor_is_affiliated_to_current_partner(@donor)
          render_errors({ donor: "Could not find a donor with ID #{params[:id]}" }, :not_found)
        end
      end

      private

      def donor_params
        params
          .require(:donor)
          .permit(:first_name, :last_name, :entity_name, :email, :title,
                  :house_name_or_number, :postcode, :uk_gift_aid_accepted)
      end

      def search_params
        params[:email]
      end

      def partner_affiliation(donor)
        @partner_affiliation ||= Partners::GetPartnerAffiliationByDonorAndPartner.call(donor: donor, partner: current_partner)
      end

      def donor_is_affiliated_to_current_partner(donor)
        partner_affiliation(donor).present?
      end
    end
  end
end
