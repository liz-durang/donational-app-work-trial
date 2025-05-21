require 'rails_helper'

RSpec.describe 'GET /partners/:partner_id/reports/donations', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let!(:partner_donor) { create(:donor) }
  let!(:partner) { create(:partner, donors: [partner_donor]) }
  let(:start_date) { (Time.zone.today - 1.month).in_time_zone('Eastern Time (US & Canada)') }
  let(:end_date) { Time.zone.today.in_time_zone('Eastern Time (US & Canada)') }
  let(:donated_between) { start_date.at_beginning_of_day..end_date.at_end_of_day }

  before do
    login_as(partner_donor)
    allow(Partners::GetDonationsExport).to receive(:call).and_return(OpenStruct.new(to_sql: 'SELECT 1'))
    allow_any_instance_of(Partners::ReportsController).to receive(:stream_sql_data_as_csv)
  end

  context 'when the donor has permission' do
    it 'returns a successful response' do
      get donations_partner_reports_path(partner, format: :csv,
                                                  params: { start_at: start_date.to_s, end_at: end_date.to_s })
      expect(response).to have_http_status(:success)
    end

    it 'calls the GetDonationsExport command' do
      expect(Partners::GetDonationsExport).to receive(:call).with(partner:, donated_between:)
      get donations_partner_reports_path(partner, format: :csv,
                                                  params: { start_at: start_date.to_s, end_at: end_date.to_s })
    end

    it 'calls stream_sql_data_as_csv with the correct arguments' do
      expected_filename = "#{partner.name.parameterize}-donations-#{start_date.to_date.iso8601}-to-#{end_date.to_date.iso8601}.csv"
      expect_any_instance_of(Partners::ReportsController).to receive(:stream_sql_data_as_csv).with(
        'SELECT 1',
        filename: expected_filename
      )
      get donations_partner_reports_path(partner, format: :csv,
                                                  params: { start_at: start_date.to_s, end_at: end_date.to_s })
    end
  end

  context 'when the donor does not have permission' do
    let!(:other_donor) { create(:donor) }

    before do
      login_as(other_donor)
    end

    it 'redirects to the edit partner path' do
      get donations_partner_reports_path(partner, format: :csv,
                                                  params: { start_at: start_date.to_s, end_at: end_date.to_s })
      expect(response).to redirect_to(edit_partner_path(partner))
    end
  end
end
