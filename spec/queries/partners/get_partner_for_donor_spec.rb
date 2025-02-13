require 'rails_helper'

RSpec.describe Partners::GetPartnerForDonor, type: :query do
  let(:donor) { create(:donor) }
  let(:partner) { create(:partner) }
  let(:default_partner) { create(:partner, name: Partner::DEFAULT_PARTNER_NAME) }
  let!(:partner_affiliation) { create(:partner_affiliation, donor: donor, partner: partner, created_at: 1.day.ago) }
  let!(:older_affiliation) { create(:partner_affiliation, donor: donor, partner: create(:partner), created_at: 2.days.ago) }

  describe '#call' do
    subject { described_class.new.call(donor: donor) }

    context 'when the donor has partner affiliations' do
      it 'returns the most recent partner for the given donor' do
        expect(subject).to eq(partner)
      end
    end

    context 'when the donor has no partner affiliations' do
      before do
        allow_any_instance_of(Partners::GetPartnerForDonor).to receive(:default_partner).and_return(default_partner)
        PartnerAffiliation.destroy_all
      end

      it 'returns the default partner' do
        expect(subject).to eq(default_partner)
      end
    end

    context 'when the donor is blank' do
      subject { described_class.new.call(donor: nil) }
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
