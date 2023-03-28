require 'rails_helper'
require 'support/capybara_form_helpers'

RSpec.describe "Donor makes a donation from a donors's profile page", type: :feature do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:stripe_helper) { StripeMock.create_test_helper }

  scenario 'as a new visitor without filling in required fields', js: true do
    username = 'donor-requiredfields'
    create_new_donor!(username)

    visit profiles_path(username)

    expect(page).to have_content('All charities in this portfolio have been vetted by industry experts')

    click_on 'Next'
    expect(page).to have_content('This field is required')
    submit_donor_info

    click_on 'Next'
    expect(page).to have_content('This field is required')
    fill_in_donation_info

    page.execute_script("document.getElementById('payment-method-id').value = '#{payment_method.id}';")
    page.execute_script("document.getElementById('payment-validated').click();")

    date_in_three_months_on_the_15th = next_15th_of_the_month_after(Date.today + 3.months)
    expect(page).to have_content("Your next donation of $50.00 is scheduled for #{date_in_three_months_on_the_15th.to_formatted_s(:long_ordinal)}")

    click_on 'View my portfolio'
    expect(page).to have_content('Your personal charity portfolio')
  end

  scenario 'as a new visitor', js: true do
    username = 'donor'
    create_new_donor!(username)

    visit profiles_path(username)

    submit_donor_info

    fill_in_donation_info

    page.execute_script("document.getElementById('payment-method-id').value = '#{payment_method.id}';")
    page.execute_script("document.getElementById('payment-validated').click();")

    date_in_three_months_on_the_15th = next_15th_of_the_month_after(Date.today + 3.months)
    expect(page).to have_content("Your next donation of $50.00 is scheduled for #{date_in_three_months_on_the_15th.to_formatted_s(:long_ordinal)}")

    click_on 'View my portfolio'
    expect(page).to have_content('Your personal charity portfolio')
  end

  def create_new_donor!(username)
    donor = Donor.create(
      first_name: 'Donny',
      last_name: 'Donator',
      email: 'donny@donator.com',
      username: username
    )

    charity_1 = create(:organization, name: 'Charity 1')
    charity_2 = create(:organization, name: 'Charity 2')
    portfolio = create(:portfolio)

    Portfolios::AddOrganizationsAndRebalancePortfolio.run(portfolio: portfolio, organization_eins: [charity_1.ein, charity_2.ein])

    Portfolios::SelectPortfolio.run(donor: donor, portfolio: portfolio)

    partner = Partner.create(
      name: 'One for the World',
      currency: 'USD',
      payment_processor_account_id: 'acc_123'
    )

    Partners::AffiliateDonorWithPartner.run(donor: donor, partner: partner)
  end

  def submit_donor_info
    fill_in 'profile_contribution[first_name]', with: 'Ian'
    fill_in 'profile_contribution[last_name]', with: 'Yamey'
    fill_in 'profile_contribution[email]', with: "ian+#{RSpec.configuration.seed}@donational.org"

    click_on 'Next'
  end

  def fill_in_donation_info
    find('a', text: /50/).click

    # Future date the donation
    find('[data-accordion-trigger="show-date"]').click
    select Date::ABBR_MONTHNAMES[3.months.from_now.month]
    select 3.months.from_now.year

    select 'Monthly'

    click_on 'Next'
  end

  def payment_method
    billing_details_params = {
      name: 'Donatello Donor',
      address: {
        postal_code: '19702'
      }
    }

    card_params = {
      number: '4242424242424242',
      exp_month: 12,
      exp_year: 1.year.from_now.year,
      cvc: '999',
      last4: '4242'
    }

    Stripe::PaymentMethod.create({ type: 'card', card: card_params, billing_details: billing_details_params })
  end

  def next_15th_of_the_month_after(date)
    month = date.next_month.month
    year = date.next_month.year

    Date.new(year, month, 15)
  end
end
