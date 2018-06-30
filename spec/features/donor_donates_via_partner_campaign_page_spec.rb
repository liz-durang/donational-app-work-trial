require 'rails_helper'
require 'support/capybara_form_helpers'

RSpec.describe "Donor makes a donation from a partner's campaign page", type: :feature do
  before do
    create_new_partner!
  end

  scenario 'as a new visitor', js: true do
    visit campaigns_path('1ftw-wharton')
    expect(page).to have_content('The Wharton School')

    click_on_label '$20'
    select 'Yearly'

    # Future date the donation
    find('[data-accordion-trigger="show-date"]').click
    find('input[type="date"]').click
    [1, 2, 3].each do |i|
      find('.calendar-nav-next-month').click
      month_name = i.months.from_now.strftime("%B")
      expect(page).to have_content(month_name)
    end
    click_on '12'

    fill_in 'campaign_contribution[first_name]', with: 'Ian'
    fill_in 'campaign_contribution[last_name]', with: 'Yamey'
    fill_in 'campaign_contribution[email]', with: "ian+#{RSpec.configuration.seed}@donational.org"

    expect(page).to have_content('Which city will you be living in when your donation commences?')
    fill_in 'campaign_contribution[donor_questions][city]', with: 'London'
    select 'Harvard'
    click_on_label 'Top Picks'

    fill_in 'Card Number', with: '4111111111111111'
    select 12
    select 1.year.from_now.year
    fill_in 'First name', with: 'Ian'
    fill_in 'Last name', with: 'Yamey'
    fill_in 'CVV', with: 123
    click_on 'Donate'
    sleep 2
    date_in_two_months_on_the_12th = Date.new(Date.today.year, Date.today.month + 3, 12).to_formatted_s(:long_ordinal)
    expect(page).to have_content("Your next annual donation of $20 is scheduled for #{date_in_two_months_on_the_12th}")
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
    portfolio = create(:portfolio)
    Portfolios::AddOrganizationsAndRebalancePortfolio.run(
      portfolio: portfolio, organization_eins: [charity_1.ein, charity_2.ein]
    )
    ManagedPortfolio.create(
      partner: partner,
      portfolio: portfolio,
      name: 'Top Picks'
    )
  end
end
