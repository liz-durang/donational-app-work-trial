require 'rails_helper'

describe 'POST api/v1/contributions/', type: :request do
  let(:contribution) { Contribution.last }
  let(:donor) { create(:donor) }
  let(:organization) { create(:organization) }
  let(:partner) { create(:partner) }
  let(:portfolio) { create(:portfolio) }
  let(:currency) { 'USD' }
  let(:amount_cents) { 200 }
  let(:external_reference_id) { 'external_reference_id_1' }
  let(:mark_as_paid) { true }
  let(:receipt) {
    {
      method: "ACH",
      account: "jp_morgan_chase_1",
      memo: "some_entry_id",
      transfer_date: "2019-01-01"
    }
  }

  describe 'POST create' do
    context 'for a single organization' do
      let(:donor_id) { donor.id }

      let(:params) do
        {
          contribution: {
            donor_id: donor_id,
            amount_cents: amount_cents,
            currency: currency,
            organization_ein: organization.ein,
            external_reference_id: external_reference_id,
            mark_as_paid: mark_as_paid,
            receipt: receipt
          }
        }
      end

      it 'returns a successful response' do
        post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        expect(response).to have_http_status(:success)
      end

      it 'creates the contribution' do
        expect {
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.to change(Contribution, :count).by(1)
      end

      it 'returns the contribution' do
        post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(json[:contribution][:id]).to eq(contribution.id)
        expect(json[:contribution][:donor_id]).to eq(contribution.donor_id)
        expect(json[:contribution][:amount_cents]).to eq(contribution.amount_cents)
        expect(json[:contribution][:external_reference_id]).to eq(contribution.external_reference_id)
        expect(json[:contribution][:processed_at]).not_to be(nil)
        expect(json[:contribution][:receipt]).to eq(contribution.receipt)
        expect(json[:contribution][:portfolio_id]).to eq(contribution.portfolio_id)
      end

      context 'when it is not mark as paid' do
        let(:mark_as_paid) { nil }
        let(:receipt) { nil }

        it 'returns a successful response' do
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

          expect(response).to have_http_status(:success)
        end

        it 'creates the contribution' do
          expect {
            post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
          }.to change(Contribution, :count).by(1)
        end

        it 'returns the contribution' do
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:contribution][:id]).to eq(contribution.id)
          expect(json[:contribution][:donor_id]).to eq(contribution.donor_id)
          expect(json[:contribution][:amount_cents]).to eq(contribution.amount_cents)
          expect(json[:contribution][:external_reference_id]).to eq(contribution.external_reference_id)
          expect(json[:contribution][:processed_at]).to be(nil)
          expect(json[:contribution][:receipt]).to eq(contribution.receipt)
          expect(json[:contribution][:portfolio_id]).to eq(contribution.portfolio_id)
        end
      end

      context 'when it is mark as paid and receipt is not provided' do
        let(:mark_as_paid) { true }
        let(:receipt) { nil }

        it 'does not create a contribution' do
          expect {
            post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
          }.not_to change { Contribution.count }
        end

        it 'does not return a successful response' do
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

          json = JSON.parse(response.body).with_indifferent_access
          expect(response.status).to eq(422)
          expect(json[:errors][0]).to eq("Receipt can't be nil")
        end
      end

      context 'when the donor is invalid' do
        let(:donor_id) { 'invalid_donor' }

        it 'does not create a contribution' do
          expect {
            post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
          }.not_to change { Contribution.count }
        end

        it 'does not return a successful response' do
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

          json = JSON.parse(response.body).with_indifferent_access
          expect(response.status).to eq(422)
          expect(json[:errors][0]).to eq("Suggested By can't be nil")
        end
      end

      context 'when the amount is not correct' do
        let(:amount_cents) { 0 }

        it 'does not create a contribution' do
          expect {
            post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
          }.not_to change { Contribution.count }
        end

        it 'does not return a successful response' do
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

          json = JSON.parse(response.body).with_indifferent_access
          expect(response.status).to eq(422)
          expect(json[:errors][0]).to eq('Amount Cents is too small')
        end
      end
    end

    context 'for a portfolio' do
      let(:donor_email) { 'donny@donator.com' }
      let(:donor_first_name) { 'Donny' }
      let(:donor_last_name) { 'Donator' }

      let(:params) do
        {
          contribution: {
            donor_email: donor_email,
            donor_first_name: donor_first_name,
            donor_last_name: donor_last_name,
            amount_cents: amount_cents,
            currency: currency,
            portfolio_id: portfolio.id,
            mark_as_paid: mark_as_paid,
            receipt: receipt
          }
        }
      end

      it 'returns a successful response' do
        post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        expect(response).to have_http_status(:success)
      end

      it 'creates the contribution' do
        expect {
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.to change(Contribution, :count).by(1)
      end

      it 'creates the donor' do
        expect {
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
        }.to change(Donor, :count)
      end

      it 'returns the contribution' do
        post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

        json = JSON.parse(response.body).with_indifferent_access
        expect(json[:contribution][:id]).to eq(contribution.id)
        expect(json[:contribution][:donor_id]).to eq(contribution.donor_id)
        expect(json[:contribution][:amount_cents]).to eq(contribution.amount_cents)
        expect(json[:contribution][:external_reference_id]).to eq(contribution.external_reference_id)
        expect(json[:contribution][:processed_at]).not_to be(nil)
        expect(json[:contribution][:receipt]).to eq(contribution.receipt)
        expect(json[:contribution][:portfolio_id]).to eq(contribution.portfolio_id)
      end

      context 'when it is not mark as paid' do
        let(:mark_as_paid) { nil }
        let(:receipt) { nil }

        it 'returns a successful response' do
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

          expect(response).to have_http_status(:success)
        end

        it 'creates the contribution' do
          expect {
            post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
          }.to change(Contribution, :count).by(1)
        end

        it 'returns the contribution' do
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

          json = JSON.parse(response.body).with_indifferent_access
          expect(json[:contribution][:id]).to eq(contribution.id)
          expect(json[:contribution][:donor_id]).to eq(contribution.donor_id)
          expect(json[:contribution][:amount_cents]).to eq(contribution.amount_cents)
          expect(json[:contribution][:external_reference_id]).to eq(contribution.external_reference_id)
          expect(json[:contribution][:processed_at]).to be(nil)
          expect(json[:contribution][:receipt]).to eq(contribution.receipt)
          expect(json[:contribution][:portfolio_id]).to eq(contribution.portfolio_id)
        end
      end

      context 'when it is mark as paid and receipt is not provided' do
        let(:mark_as_paid) { true }
        let(:receipt) { nil }

        it 'does not create a contribution' do
          expect {
            post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
          }.not_to change { Contribution.count }
        end

        it 'does not return a successful response' do
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

          json = JSON.parse(response.body).with_indifferent_access
          expect(response.status).to eq(422)
          expect(json[:errors][0]).to eq("Receipt can't be nil")
        end
      end

      context 'when the donor name is invalid' do
        let(:donor_first_name) { '' }
        let(:donor_last_name) { '' }

        it 'does not create a contribution' do
          expect {
            post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
          }.not_to change { Contribution.count }
        end

        it 'does not return a successful response' do
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

          json = JSON.parse(response.body).with_indifferent_access
          expect(response.status).to eq(422)
          expect(json[:errors][0]).to eq("First Name can't be blank")
        end
      end

      context 'when the amount is not correct' do
        let(:amount_cents) { 0 }

        it 'does not create a contribution' do
          expect {
            post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json
          }.not_to change { Contribution.count }
        end

        it 'does not return a successful response' do
          post api_v1_contributions_path, params: params, headers: { 'X-Api-Key': partner.api_key }, as: :json

          json = JSON.parse(response.body).with_indifferent_access
          expect(response.status).to eq(422)
          expect(json[:errors][0]).to eq('Amount Cents is too small')
        end
      end
    end
  end
end
