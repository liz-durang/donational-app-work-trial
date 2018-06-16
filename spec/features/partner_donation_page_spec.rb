require 'rails_helper'
require 'support/capybara_form_helpers'

RSpec.describe "Donor makes a donation from a partner's campaign page", type: :feature do
  before do
    Campaign.create(
      partner: Partner.create(name: 'One for the World', platform_fee_percentage: 0.02),
      title: 'The Wharton School',
      slug: '1ftw-wharton',
      default_contribution_amounts: [10, 20, 50, 100, 200]
    )
    create(:organization, name: 'Charity 1')
    create(:organization, name: 'Charity 2')
  end

  scenario 'as a new visitor', js: true do
    visit campaigns_path('1ftw-wharton')
    expect(page).to have_content('The Wharton School')
    fill_in 'campaign_contribution[first_name]', with: 'Ian'
    fill_in 'campaign_contribution[last_name]', with: 'Yamey'
    fill_in 'campaign_contribution[email]', with: "ian+#{RSpec.configuration.seed}@donational.org"
    click_on_label '$20'
    click_on_label 'Monthly'
    fill_in 'Card Number', with: '4111111111111111'
    select 12
    select 1.year.from_now.year
    fill_in 'First name', with: 'Ian'
    fill_in 'Last name', with: 'Yamey'
    fill_in 'CVV', with: 123
    click_on 'Donate'
    sleep 2
    expect(page).to have_content 'You have made 1 donation to your charity portfolio.'
    expect(page).to have_content '$20'
  end
end
