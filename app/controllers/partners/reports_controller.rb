# frozen_string_literal: true

module Partners
  class ReportsController < ApplicationController
    include Secured
    include ActionController::Live

    before_action :ensure_donor_has_permission!

    def index
      @view_model = OpenStruct.new(
        partner: partner
      )
    end

    def donors
      respond_to do |format|
        format.csv do
          stream_sql_data_as_csv(
            Partners::GetDonorExport.call(partner: partner).to_sql,
            filename: "#{partner.name.parameterize}-donors-#{Date.today.iso8601}.csv"
          )
        end
      end
    end

    def donations
      respond_to do |format|
        format.csv do
          donations = Partners::GetDonationsExport.call(
            partner: partner,
            donated_between: donated_between
          )
          stream_sql_data_as_csv(donations.to_sql, filename: filename_with_timeframe)
        end
      end
    end

    def organizations
      respond_to do |format|
        format.csv do
          donations = Partners::GetOrganizationsExport.call(
            partner: partner,
            donated_between: donated_between
          )
          stream_sql_data_as_csv(donations.to_sql, filename: filename_with_timeframe)
        end
      end
    end

    def refunded
      respond_to do |format|
        format.csv do
          donations = Partners::GetRefundedExport.call(
            partner: partner,
            donated_between: donated_between
          )
          stream_sql_data_as_csv(donations.to_sql, filename: filename_with_timeframe)
        end
      end
    end

    def gift_aid
      return head :forbidden unless partner.supports_gift_aid?

      respond_to do |format|
        format.csv do
          donations = Partners::GetGiftAidExport.call(
            partner: partner,
            donated_between: donated_between
          )
          stream_sql_data_as_csv(donations.to_sql, filename: filename_with_timeframe)
        end
      end
    end

    private

    def ensure_donor_has_permission!
      unless current_donor.partners.exists?(id: partner.id)
        flash[:error] = "Sorry, you don't have permission to export data from this partner account"
        redirect_to edit_partner_path(partner)
      end
    end

    def partner
      @partner ||= Partners::GetPartnerById.call(id: params[:partner_id])
    end

    def donated_between
      start_date.at_beginning_of_day..end_date.at_end_of_day
    end

    def start_date
      Date.parse(params[:start_at])
    end

    def end_date
      Date.parse(params[:end_at])
    end

    def filename_with_timeframe
      "#{partner.name.parameterize}-#{action_name}-#{start_date.iso8601}-to-#{end_date.iso8601}.csv"
    end

    def stream_sql_data_as_csv(sql_query, filename:)
      response.headers['Content-Type'] = 'application/octet-stream'
      response.headers['Content-Disposition'] = "inline; filename=#{filename}"

      conn = ActiveRecord::Base.connection.raw_connection
      conn.copy_data "COPY (#{sql_query}) TO STDOUT WITH CSV HEADER;" do
        while row_from_db = conn.get_copy_data
          response.stream.write row_from_db
        end
      end
    ensure
      response.stream.close
    end
  end
end
