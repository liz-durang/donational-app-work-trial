require 'rails_helper'
require 'support/capybara_form_helpers'

RSpec.describe "Donor makes a donation from a partner's campaign page", type: :feature do
  before do
    create_new_partner!
  end

  scenario 'as a new visitor', js: true do
    visit campaigns_path('1ftw-wharton')
    expect(page).to have_content('The Wharton School')
    fill_in 'campaign_contribution[first_name]', with: 'Ian'
    fill_in 'campaign_contribution[last_name]', with: 'Yamey'
    fill_in 'campaign_contribution[email]', with: "ian+#{RSpec.configuration.seed}@donational.org"
    click_on_label '$20'
    click_on_label 'Monthly'
    expect(page).to have_content('Which city will you be living in when your donation commences?')
    fill_in 'campaign_contribution[donor_questions][city]', with: 'London'
    select 'Harvard'
    select 'Top Picks'
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

  def create_new_partner!
    # TODO: This should be done by automating Partner/Campaign creation through the Admin interface

    partner = Partner.create(
      name: 'One for the World',
      platform_fee_percentage: 0.02,
      donor_questions_schema: {
        questions: [
          {
            name: 'school',
            title: 'What organization/school are you affiliated with?',
            type: 'select',
            options: ['Harvard', 'Wharton', 'Other'],
            required: true
          },
          {
            name: 'city',
            title: 'Which city will you be living in when your donation commences?',
            type: 'text',
            required: false
          }
        ]
      }
    )
    Campaign.create(
      partner: partner,
      title: 'The Wharton School',
      slug: '1ftw-wharton',
      default_contribution_amounts: [10, 20, 50, 100, 200]
    )

    charity_1 = create(:organization, name: 'Charity 1')
    charity_2 = create(:organization, name: 'Charity 2')
    charity_3 = create(:organization, name: 'Charity 3')

    PortfolioTemplate.create(
      partner: partner,
      title: 'Top Picks',
      organization_eins: [charity_1.ein, charity_2.ein]
    )
  end
end
