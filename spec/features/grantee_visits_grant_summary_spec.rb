# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Grantee organization visits grant page', type: :feature do
  it 'shows processed grants and all the donations' do
    org = create(:organization, name: 'Living Goods')
    grant = create(:grant, processed_at: 1.week.ago, amount_cents: 100_50, organization: org)
    create(:donation, grant: grant, amount_cents: 60_00)
    create(:donation, grant: grant, amount_cents: 40_50)

    visit grant_path(grant)

    expect(page).to have_content('Grant to Living Goods')
    expect(page).to have_content('Amount:$100.50')
    expect(page).to have_content('$60.00')
    expect(page).to have_content('$40.50')
  end
end
