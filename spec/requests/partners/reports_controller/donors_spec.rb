require 'rails_helper'

RSpec.describe 'GET /partners/:partner_id/reports/donors', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let!(:partner_donor) { create(:donor) }
  let!(:partner) { create(:partner, donors: [partner_donor]) }
  let(:donor_export_data) { [%w[header1 header2], %w[value1 value2]] }

  before do
    login_as(partner_donor)
    allow(Partners::GetDonorExport).to receive(:call).with(partner:).and_return(OpenStruct.new(to_sql: 'SELECT 1'))
    allow_any_instance_of(Partners::ReportsController).to receive(:stream_sql_data_as_csv)
  end

  context 'when the donor has permission' do
    it 'returns a successful response' do
      get donors_partner_reports_path(partner, format: :csv)
      expect(response).to have_http_status(:success)
    end

    it 'calls the GetDonorExport command' do
      expect(Partners::GetDonorExport).to receive(:call).with(partner:)
      get donors_partner_reports_path(partner, format: :csv)
    end

    it 'calls stream_sql_data_as_csv with the correct arguments' do
      expect_any_instance_of(Partners::ReportsController).to receive(:stream_sql_data_as_csv).with(
        'SELECT 1',
        filename: "#{partner.name.parameterize}-donors-#{Date.today.iso8601}.csv"
      )
      get donors_partner_reports_path(partner, format: :csv)
    end
  end

  context 'when the donor does not have permission' do
    let!(:other_donor) { create(:donor) }

    before do
      login_as(other_donor)
    end

    it 'redirects to the edit partner path' do
      get donors_partner_reports_path(partner, format: :csv)
      expect(response).to redirect_to(edit_partner_path(partner))
    end
  end
end
