require 'rails_helper'
require 'support/capybara_form_helpers'

RSpec.describe "Donor makes a donation from a partner's campaign page", type: :feature do
  let(:stripe_helper) { StripeMock.create_test_helper }
  before do
    StripeMock.start
    allow_any_instance_of(Payments::GeneratePlaidLinkToken).to receive(:call).and_return(
      OpenStruct.new(link_token: 'token_of_my_affection')
    )
  end
  after { StripeMock.stop }

  scenario 'as a new visitor without filling in required fields', js: true do
    slug = '1ftw-requiredfields'
    create_new_partner!('USD', slug, nil)

    visit campaigns_path(slug)

    expect(page).not_to have_content('Managed Portfolio that has been hidden')
    find("#portfolio-link-#{ManagedPortfolio.find_by(name: 'Top Picks').id}").click
    find("a.icon.right-arrow").click

    submit_donor_info

    fill_in_donation_info

    card_token = stripe_helper.generate_card_token(last4: '9191', name: 'Donatello')
    page.execute_script("document.getElementById('payment_token').value = '#{card_token}';")
    page.execute_script("document.getElementById('payment-validated').click();")

    expect(page).to have_content('Which city will you be living in when your donation commences?')

    click_on 'Donate'

    expect(page).to have_content('This field is required')

    fill_in 'campaign_contribution[donor_questions][city]', with: 'London'
    select 'Wharton'

    click_on 'Donate'

    date_in_three_months_on_the_15th = next_15th_of_the_month_after(Date.today + 3.months)
    expect(page).to have_content("Your next donation of $200.00 is scheduled for #{date_in_three_months_on_the_15th.to_formatted_s(:long_ordinal)}")

  end

  scenario 'as a new visitor with redirect', js: true do
    slug = '1ftw-redirect'
    thank_you_url = 'https://www.1fortheworld.org'
    create_new_partner!('USD', slug, thank_you_url)

    visit campaigns_path(slug)

    expect(page).not_to have_content('Managed Portfolio that has been hidden')
    find("#portfolio-link-#{ManagedPortfolio.find_by(name: 'Top Picks').id}").click

    find("a.icon.right-arrow").click

    submit_donor_info
    fill_in_donation_info

    card_token = stripe_helper.generate_card_token(last4: '9191', name: 'Donatello')
    page.execute_script("document.getElementById('payment_token').value = '#{card_token}';")
    page.execute_script("document.getElementById('payment-validated').click();")

    expect(page).to have_content('Which city will you be living in when your donation commences?')

    fill_in 'campaign_contribution[donor_questions][city]', with: 'London'
    select 'Wharton'

    click_on 'Donate'

    expect(page).to have_current_path(thank_you_url, url: true)

  end

  scenario 'as a new visitor', js: true do
    slug = '1ftw-wharton'
    create_new_partner!('USD', slug, nil)

    visit campaigns_path(slug)

    expect(page).not_to have_content('Managed Portfolio that has been hidden')
    find("#portfolio-link-#{ManagedPortfolio.find_by(name: 'Top Picks').id}").click

    find("a.icon.right-arrow").click

    submit_donor_info

    fill_in_donation_info

    card_token = stripe_helper.generate_card_token(last4: '9191', name: 'Donatello')
    page.execute_script("document.getElementById('payment_token').value = '#{card_token}';")
    page.execute_script("document.getElementById('payment-validated').click();")

    expect(page).to have_content('Which city will you be living in when your donation commences?')

    fill_in 'campaign_contribution[donor_questions][city]', with: 'London'
    select 'Wharton'

    click_on 'Donate'
    date_in_three_months_on_the_15th = next_15th_of_the_month_after(Date.today + 3.months)

    expect(page).to have_content("Your next donation of $200.00 is scheduled for #{date_in_three_months_on_the_15th.to_formatted_s(:long_ordinal)}")

    click_on 'View my portfolio'

    visit edit_accounts_path
    expect(find_field('donor_responses[city]').value).to eq 'London'
    find('[data-target="ask-to-pause-modal"]').click
    within('#ask-to-pause-modal') do
      find('[value="Pause my donations for 3 months"]').click
    end
    expect(page).to have_content("Your next donation of $200.00 is scheduled for #{(date_in_three_months_on_the_15th + 3.months).to_formatted_s(:long_ordinal)}")

    select 'Other Portfolio'
    click_on 'Change my donation'
  end

  scenario 'as a new UK visitor', js: true do
    slug = '1ftw-uk'
    create_new_partner!('GBP', slug, nil)
    visit campaigns_path(slug)

    expect(page).not_to have_content('Managed Portfolio that has been hidden')
    find("#portfolio-link-#{ManagedPortfolio.find_by(name: 'Top Picks').id}").click

    find("a.icon.right-arrow").click

    submit_donor_info

    find('#gift_aid_checkbox').set(true)
    fill_in 'campaign_contribution[house_name_or_number]', with: '100'
    fill_in 'campaign_contribution[postcode]', with: 'PO1 3AX'
    fill_in 'campaign_contribution[title]', with: 'Mr'

    fill_in_donation_info

    card_token = stripe_helper.generate_card_token(last4: '9191', name: 'Donatello')
    page.execute_script("document.getElementById('payment_token').value = '#{card_token}';")
    page.execute_script("document.getElementById('payment-validated').click();")

    expect(page).to have_content('Which city will you be living in when your donation commences?')

    fill_in 'campaign_contribution[donor_questions][city]', with: 'London'
    select 'Wharton'

    click_on 'Donate'

    date_in_three_months_on_the_15th = next_15th_of_the_month_after(Date.today + 3.months)
    expect(page).to have_content("Your next donation of £200.00 is scheduled for #{date_in_three_months_on_the_15th.to_formatted_s(:long_ordinal)}")

    visit edit_accounts_path
    expect(find_field('donor_responses[city]').value).to eq 'London'
    find('[data-target="ask-to-pause-modal"]').click
    within('#ask-to-pause-modal') do
      find('[value="Pause my donations for 3 months"]').click
    end
    expect(page).to have_content("Your next donation of £200.00 is scheduled for #{(date_in_three_months_on_the_15th + 3.months).to_formatted_s(:long_ordinal)}")

  end

  # TODO: This should be done by automating Partner/Campaign creation through the Admin interface
  def create_new_partner!(currency, slug, thank_you_url)
    one_for_the_world_operating_costs_charity = create(:organization, name: 'OFTW Operating Costs')

    partner = Partner.create(
      name: 'One for the World',
      currency: currency,
      platform_fee_percentage: 0.02,
      after_donation_thank_you_page_url: thank_you_url,
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
      slug: slug,
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

  def next_15th_of_the_month_after(date)
    month = date.next_month.month
    year = date.next_month.year

    Date.new(year, month, 15)
  end

  def submit_donor_info
    fill_in 'campaign_contribution[first_name]', with: 'Ian'
    fill_in 'campaign_contribution[last_name]', with: 'Yamey'
    fill_in 'campaign_contribution[email]', with: "ian+#{RSpec.configuration.seed}@donational.org"


    find("a.icon.right-arrow", wait: 3).click
  end

  def fill_in_donation_info
    find('a', text: /200/).click

    # Future date the donation
    find('[data-accordion-trigger="show-date"]').click
    select Date::ABBR_MONTHNAMES[3.months.from_now.month]
    select 3.months.from_now.year

    select 'Monthly'

    expect(page).to have_content('Your pledge starts in 3 months.')

    find("a.icon.right-arrow", wait: 3).click
  end
end
