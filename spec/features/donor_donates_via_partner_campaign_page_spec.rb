require 'rails_helper'
require 'support/capybara_form_helpers'

RSpec.describe "Donor makes a donation from a partner's campaign page", type: :feature do
  let(:stripe_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

  before do
    create_new_partner!
  end

  scenario 'as a new visitor', js: true do
    visit campaigns_path('1ftw-wharton')

    expect(page).not_to have_content('Managed Portfolio that has been hidden')
    click_on_label 'Top Picks'

    click_on 'Next'

    fill_in 'campaign_contribution[first_name]', with: 'Ian'
    fill_in 'campaign_contribution[last_name]', with: 'Yamey'
    fill_in 'campaign_contribution[email]', with: "ian+#{RSpec.configuration.seed}@donational.org"

    click_on 'Next'

    expect(page).to have_content('Which city will you be living in when your donation commences?')
    fill_in 'campaign_contribution[donor_questions][city]', with: 'London'
    select 'Wharton'

    click_on 'Next'

    find('a', text: '$200').click

    # Future date the donation
    find('[data-accordion-trigger="show-date"]').click
    find('input[type="date"]').click
    [1, 2, 3].each do |i|
      find('.calendar-nav-next-month').click
      month_name = i.months.from_now.strftime("%B")
      expect(page).to have_content(month_name)
    end
    click_on '12'

    select 'Monthly'

    expect(page).to have_content('Please select here if you are happy for some of your donations to go to One for the World')
    click_on '10%'

    click_on 'Next'

    card_token = stripe_helper.generate_card_token(last4: '9191', name: 'Donatello')
    page.execute_script("document.getElementById('payment_token').value = '#{card_token}';")
    page.execute_script("document.getElementById('payment-form').submit();")

    date_in_two_months_on_the_12th = (Date.new(Date.today.year, Date.today.month, 12) + 3.months).to_formatted_s(:long_ordinal)
    expect(page).to have_content("Your next donation of $200.00 is scheduled for #{date_in_two_months_on_the_12th}")

    click_on 'View my portfolio'

    visit edit_accounts_path
    expect(find_field('donor_responses[city]').value).to eq 'London'

    select 'Other Portfolio'
    click_on 'Update donation plan'
  end

  # TODO: This should be done by automating Partner/Campaign creation through the Admin interface
  def create_new_partner!
    one_for_the_world_operating_costs_charity = create(:organization, name: 'OFTW Operating Costs')
    
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
        ],
      },
      operating_costs_text: "For every $1 donated to One for the World, we raise $12 for effective charities. Please select here if you are happy for some of your donations to go to One for the World.",
      operating_costs_organization: one_for_the_world_operating_costs_charity,
      payment_processor_account_id: 'acc_123'
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
    ManagedPortfolio.create(
      partner: partner,
      portfolio: portfolio,
      name: 'Managed Portfolio that has been hidden',
      hidden_at: 1.day.ago
    )

    charity_4 = create(:organization, name: 'Charity 4')
    charity_5 = create(:organization, name: 'Charity 5')
    other_portfolio = create(:portfolio)
    Portfolios::AddOrganizationsAndRebalancePortfolio.run(
      portfolio: portfolio, organization_eins: [charity_4.ein, charity_5.ein]
    )
    ManagedPortfolio.create(
      partner: partner,
      portfolio: other_portfolio,
      name: 'Other Portfolio'
    )
  end
end
