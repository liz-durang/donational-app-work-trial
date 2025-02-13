# == Schema Information
#
# Table name: partners
#
#  id                                :uuid             not null, primary key
#  name                              :string
#  website_url                       :string
#  description                       :text
#  platform_fee_percentage           :decimal(, )      default(0.0)
#  primary_branding_color            :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  donor_questions_schema            :jsonb
#  payment_processor_account_id      :string
#  api_key                           :string
#  operating_costs_text              :string
#  operating_costs_organization_ein  :string
#  currency                          :string           default("usd"), not null
#  email_receipt_preamble            :text
#  after_donation_thank_you_page_url :string
#  receipt_first_paragraph           :text
#  receipt_second_paragraph          :text
#  receipt_tax_info                  :text
#  receipt_charity_name              :string
#  donor_advised_fund_fee_percentage :decimal(, )      default(0.01)
#

require 'rails_helper'

RSpec.describe Partner, type: :model do
  describe 'associations' do
    it { should have_many(:campaigns) }
    it { should have_many(:contributions) }
    it { should have_many(:subscriptions) }
    it { should have_many(:managed_portfolios).order(:display_order) }
    it { should have_many(:zapier_webhooks) }
    it { should have_and_belong_to_many(:donors) }
    it { should have_one_attached(:logo) }
    it { should have_one_attached(:email_banner) }
    it { should belong_to(:operating_costs_organization).class_name('Organization').optional }
  end

  describe 'validations' do
    it 'validates correctness of the currency field', :aggregate_failures do
      valid_partner = build(:partner, currency: 'gbp')
      invalid_partner = build(:partner, currency: 'xyz')

      expect(valid_partner).to be_valid
      expect(invalid_partner).not_to be_valid
      expect(invalid_partner.errors.messages[:currency]).to include('xyz is not a valid currency iso code')
    end
  end

  describe 'Plaid compatibility' do
    around do |example|
      ClimateControl.modify(PLAID_ENABLED: 'true') do
        example.run
      end
    end

    it 'supports Plaid if the currency is USD' do
      partner = build(:partner, currency: 'usd')
      expect(partner.supports_plaid?).to be true
    end

    it 'does not support Plaid if the currency is not USD' do
      partner1 = build(:partner, currency: 'gbp')
      partner2 = build(:partner, currency: 'eur')
      expect(partner1.supports_plaid?).to be false
      expect(partner2.supports_plaid?).to be false
    end
  end

  describe 'methods' do
    describe '#accepts_operating_costs_donations?' do
      let(:partner_with_org) { create(:partner, operating_costs_organization: create(:organization)) }
      let(:partner_without_org) { create(:partner, operating_costs_organization: nil) }

      it 'returns true if operating_costs_organization is present' do
        expect(partner_with_org.accepts_operating_costs_donations?).to be true
      end

      it 'returns false if operating_costs_organization is not present' do
        expect(partner_without_org.accepts_operating_costs_donations?).to be false
      end
    end

    describe '#default_operating_costs_donation_percentages' do
      let(:partner) { create(:partner) }

      it 'returns the default operating costs donation percentages' do
        expect(partner.default_operating_costs_donation_percentages).to eq([0, 5, 10])
      end
    end

    describe '#donor_questions' do
      let(:partner) do 
        create(:partner, donor_questions_schema: { 
          'questions' => [
            { 
              'name' => 'question1', 
              'title' => 'Question 1', 
              'type' => 'text', 
              'options' => [], 
              'required' => true 
            }, 
            { 
              'name' => 'question2', 
              'title' => 'Question 2', 
              'type' => 'select', 
              'options' => ['Yes', 'No'], 
              'required' => false 
            }
          ] 
        }) 
      end

      it 'returns the donor questions schema as DonorQuestion objects' do
        questions = partner.donor_questions

        expect(questions.size).to eq(2)
        expect(questions.first).to be_a(Partner::DonorQuestion)
        expect(questions.first.name).to eq('question1')
        expect(questions.first.title).to eq('Question 1')
        expect(questions.first.type).to eq('text')
        expect(questions.first.options).to eq([])
        expect(questions.first.required).to be true

        expect(questions.second.name).to eq('question2')
        expect(questions.second.title).to eq('Question 2')
        expect(questions.second.type).to eq('select')
        expect(questions.second.options).to eq(['Yes', 'No'])
        expect(questions.second.required).to be false
      end
    end

    describe '#donor_questions=' do
      let(:partner) { create(:partner) }
      let(:new_questions) { [{ 'name' => 'question3' }, { 'name' => 'question4' }] }

      it 'sets the donor questions schema' do
        partner.donor_questions = new_questions
        expect(partner.donor_questions_schema).to eq({ 'questions' => new_questions })
      end
    end

    describe '#supports_gift_aid?' do
      let(:partner_gbp) { build(:partner, currency: 'gbp') }
      let(:partner_usd) { build(:partner, currency: 'usd') }

      it 'returns true if the currency is GBP' do
        expect(partner_gbp.supports_gift_aid?).to be true
      end

      it 'returns false if the currency is not GBP' do
        expect(partner_usd.supports_gift_aid?).to be false
      end
    end

    describe '#supports_plaid?' do
      let(:partner_usd) { build(:partner, currency: 'usd') }
      let(:partner_gbp) { build(:partner, currency: 'gbp') }

      context 'when PLAID_ENABLED is true' do
        before do
          allow(ENV).to receive(:[]).with('PLAID_ENABLED').and_return('true')
        end

        it 'returns true if the currency is USD' do
          expect(partner_usd.supports_plaid?).to be true
        end

        it 'returns false if the currency is not USD' do
          expect(partner_gbp.supports_plaid?).to be false
        end
      end

      context 'when PLAID_ENABLED is false' do
        before do
          allow(ENV).to receive(:[]).with('PLAID_ENABLED').and_return('false')
        end

        it 'returns false regardless of the currency' do
          expect(partner_usd.supports_plaid?).to be false
          expect(partner_gbp.supports_plaid?).to be false
        end
      end
    end

    describe '#active?' do
      let(:active_partner) { build(:partner, deactivated_at: nil) }
      let(:inactive_partner) { build(:partner, deactivated_at: Time.current) }

      it 'returns true if deactivated_at is nil' do
        expect(active_partner.active?).to be true
      end

      it 'returns false if deactivated_at is not nil' do
        expect(inactive_partner.active?).to be false
      end
    end

    describe '#supports_acss?' do
      let(:partner_cad) { build(:partner, currency: 'cad') }
      let(:partner_usd) { build(:partner, currency: 'usd') }

      context 'when ACSS_ENABLED is true' do
        before do
          allow(ENV).to receive(:[]).with('ACSS_ENABLED').and_return('true')
        end

        it 'returns true if the currency is CAD' do
          expect(partner_cad.supports_acss?).to be true
        end

        it 'returns false if the currency is not CAD' do
          expect(partner_usd.supports_acss?).to be false
        end
      end

      context 'when ACSS_ENABLED is false' do
        before do
          allow(ENV).to receive(:[]).with('ACSS_ENABLED').and_return('false')
        end

        it 'returns false regardless of the currency' do
          expect(partner_cad.supports_acss?).to be false
          expect(partner_usd.supports_acss?).to be false
        end
      end
    end

    describe '#generate_api_key' do
      let(:partner) { build(:partner, api_key: nil) }

      it 'generates a unique api_key before creation' do
        expect(partner.api_key).to be_nil
        partner.send(:generate_api_key)
        expect(partner.api_key).not_to be_nil
      end

      it 'does not overwrite an existing api_key' do
        existing_api_key = 'existing_api_key'
        partner.api_key = existing_api_key
        partner.send(:generate_api_key)
        expect(partner.api_key).to eq(existing_api_key)
      end

      it 'ensures the generated api_key is unique' do
        allow(SecureRandom).to receive(:base64).and_return('duplicate_key', 'unique_key')
        create(:partner, api_key: 'duplicate_key')
        partner.send(:generate_api_key)
        expect(partner.api_key).to eq('unique_key')
      end
    end
  end

  describe Partner::DonorQuestion do
    let(:donor_question) do
      described_class.new(
        name: 'question1',
        title: 'Question 1',
        type: 'text',
        options: [],
        required: true
      )
    end
  
    describe '#initialize' do
      it 'initializes with the correct attributes' do
        expect(donor_question.name).to eq('question1')
        expect(donor_question.title).to eq('Question 1')
        expect(donor_question.type).to eq('text')
        expect(donor_question.options).to eq([])
        expect(donor_question.required).to be true
      end
    end
  
    describe '#binary_select?' do
      it 'returns true if the question is a binary select' do
        donor_question = described_class.new(type: 'select', options: ['Yes', 'No'])
        expect(donor_question.binary_select?).to be true
      end
  
      it 'returns false if the question is not a binary select' do
        donor_question = described_class.new(type: 'select', options: ['Option 1', 'Option 2'])
        expect(donor_question.binary_select?).to be false
      end
    end
  
    describe '#dropdown?' do
      it 'returns true if the question is a dropdown select' do
        donor_question = described_class.new(type: 'select', options: ['Option 1', 'Option 2'])
        expect(donor_question.dropdown?).to be true
      end
  
      it 'returns false if the question is not a dropdown select' do
        donor_question = described_class.new(type: 'text')
        expect(donor_question.dropdown?).to be false
      end
    end
  end
end
