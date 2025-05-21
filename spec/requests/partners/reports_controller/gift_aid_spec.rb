require 'rails_helper'

RSpec.describe 'GET /partners/:partner_id/reports/gift_aid', type: :request do
  include Helpers::LoginHelper
  include Helpers::CommandHelper

  let!(:partner_donor) { create(:donor) }
  let!(:partner) { create(:partner, donors: [partner_donor], currency: 'GBP') }
  let(:start_date) { (Time.zone.today - 1.month).in_time_zone('Eastern Time (US & Canada)') }
  let(:end_date) { Date.today.in_time_zone('Eastern Time (US & Canada)') }
  let(:donated_between) { start_date.at_beginning_of_day..end_date.at_end_of_day }

  before do
    login_as(partner_donor)
    gift_aid_export_result = double('GiftAidExportResult', to_sql: 'SELECT 1') # rubocop:disable RSpec/VerifiedDoubles
    allow(Partners::GetGiftAidExport).to receive(:call).and_return(gift_aid_export_result)
  end

  context 'when the donor has permission and partner supports gift aid' do
    it 'returns a successful response' do
      get gift_aid_partner_reports_path(partner, format: :csv,
                                                 params: { start_at: start_date.to_s, end_at: end_date.to_s })
      expect(response).to have_http_status(:success)
    end

    it 'calls the GetGiftAidExport command' do
      expect(Partners::GetGiftAidExport).to receive(:call).with(partner:, donated_between:)
      get gift_aid_partner_reports_path(partner, format: :csv,
                                                 params: { start_at: start_date.to_s, end_at: end_date.to_s })
    end

    # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
    it 'streams CSV data with correct content and headers' do
      get gift_aid_partner_reports_path(partner, format: :csv,
                                                 params: { start_at: start_date.to_s, end_at: end_date.to_s })

      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Type']).to eq('application/octet-stream')
      expected_filename = "#{partner.name.parameterize}-gift_aid-#{start_date.to_date.iso8601}-to-#{end_date.to_date.iso8601}.csv"
      expect(response.headers['Content-Disposition']).to eq("inline; filename=#{expected_filename}")

      streamed_content = ''
      response.stream.each { |chunk| streamed_content += chunk }
      # The COPY (SELECT 1) TO STDOUT WITH CSV HEADER command in PostgreSQL typically outputs:
      # "?column?" (header line) or similar, depending on the actual query result structure
      # 1 (data line)
      # We check for these parts.
      lines = streamed_content.strip.split("\n") # Changed from '\\n' to '\n'
      expect(lines.length).to be >= 2
      expect(lines[0]).not_to be_empty # Check for a header
      expect(lines[1]).to eq('1') # Check for the data '1'
    end
  end
  # rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength

  context 'when the partner does not support gift aid' do
    before do
      # Ensure the controller uses the same partner instance that we are stubbing
      allow(Partners::GetPartnerById).to receive(:call).with(id: partner.id).and_return(partner)
      allow(partner).to receive(:supports_gift_aid?).and_return(false)
    end

    it 'returns a forbidden response' do # Changed expectation
      get gift_aid_partner_reports_path(partner, format: :csv,
                                                 params: { start_at: start_date.to_s, end_at: end_date.to_s })
      expect(response).to have_http_status(:forbidden) # Changed from :no_content
    end
  end

  context 'when the donor does not have permission' do
    let!(:other_donor) { create(:donor) }

    before do
      login_as(other_donor)
    end

    it 'redirects to the edit partner path' do
      get gift_aid_partner_reports_path(partner, format: :csv,
                                                 params: { start_at: start_date.to_s, end_at: end_date.to_s })
      expect(response).to redirect_to(edit_partner_path(partner))
    end
  end
end
