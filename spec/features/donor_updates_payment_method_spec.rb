require 'rails_helper'
require 'stripe_mock'

RSpec.describe 'Donors updates payment method', type: :feature do
  around do |example|
    ClimateControl.modify(PLAID_ENABLED: 'true') do
      example.run
    end
  end

  let!(:donor) do
    create(:donor, first_name: 'Donny', last_name: 'Donator', email: 'user@example.com')
  end
  let!(:partner) { create(:partner, :default) }
  let!(:partner_affiliation) { create(:partner_affiliation, partner: partner, donor: donor) }

  xit 'with valid credit card', js: true do
    given_a_signed_in_donor_wants_to_update_payment_method
    when_they_do_not_have_any_credit_card_added
    add_credit_card_information_and_click_save
    then_credit_card_should_be_updated
  end

  xit 'changing to Plaid', js: true do
    given_a_signed_in_donor_wants_to_update_payment_method
    when_the_donor_reveals_the_plaid_button_and_submits_their_details
    then_the_bank_account_details_should_be_present
  end

  context 'when the partner is Canadian' do
    let!(:partner) { create(:partner, :default, currency: 'cad') }

    before do
      create(:subscription, donor: donor, deactivated_at: nil)
    end

    # Skipping for now. See comment in when_the_donor_reveals_the_acss_button_and_submits_their_details
    xit 'changing to ACSS', js: true do
      given_a_signed_in_donor_wants_to_update_payment_method
      when_the_donor_reveals_the_acss_button_and_submits_their_details
      then_the_bank_account_details_should_be_present
    end
  end

  def given_a_signed_in_donor_wants_to_update_payment_method
    sign_in_as!(email: 'user@example.com')
    visit edit_accounts_path
  end

  def when_they_do_not_have_any_credit_card_added
    expect(page).to have_content('Donny Donator')
    expect(page).to have_content("You don't have a payment method on file.")
  end

  def add_credit_card_information_and_click_save
    click_on 'Add a Credit/Debit Card'
    fill_in 'cardholder_name', with: 'Donatello DonatorCard'
    fill_stripe_element('4242424242424242', (Time.zone.now + 1.year).strftime('%m%y'), '123', zip: '90210')

    click_on 'Update card'
  end

  def then_credit_card_should_be_updated
    expect(page).to have_content("Thanks, we've updated your payment information", wait: 10)
    expect(page).to have_field(disabled: true, with: 'Donatello DonatorCard')
  end

  def then_the_bank_account_details_should_be_present
    expect(page).to have_content("Thanks, we've updated your payment information", wait: 10)
    expect(page).to have_field(disabled: true, with: 'STRIPE TEST BANK')
  end

  def when_the_donor_reveals_the_plaid_button_and_submits_their_details
    click_on 'Connect your bank account'

    within_frame 'plaid-link-iframe-1' do
      click_on 'Continue'

      expect(page).to have_content('Select your institution', wait: 5)
      find_field('Search Institutions').send_keys('chime')
      click_on 'Chime'

      fill_in 'Username', with: 'user_good'
      fill_in 'Password', with: 'pass_good'

      click_on 'Submit'

      expect(page).to have_content('Plaid Checking', wait: 5)
      find('label', text: 'Plaid Checking').click
      click_on 'Continue'

      expect(page).to have_content('Success', wait: 5)
      click_on 'Continue'
    end
  end

  def when_the_donor_reveals_the_acss_button_and_submits_their_details
    click_on 'Connect your bank account'
    find('input[data-acss-target="accountHolder"]').set 'Real Donor Name'
    find('a[data-acss-target="submit"]', wait: 5).click

    # For some reason, the content of the iframe is not accessible via capybara. Even after sleeping.
    #  - Could it be related to HTTPS vs HTTP content?
    #  - When I tried Firefox instead of Chrome, it spit out some SSL errors. Not sure if it's related.
    #  - Sometimes the iframe is not found, other times it is but it has no content -- Even when we wait inside a binding.pry
    within_frame ('iframe') do
      expect(page).to have_text('Agree', wait: 10)
    end
  end

  def sign_in_as!(email:)
    OmniAuth.config.add_mock(
      :auth0,
      {
        uid: '12345', info: { email: email }
      }
    )

    visit auth_oauth2_callback_path
  end

  def fill_stripe_element(card, exp, cvc, zip: '10001')
    card_iframe = all('iframe')[0]

    within_frame card_iframe do
      card.chars.each do |piece|
        find_field('cardnumber').send_keys(piece)
      end

      exp.chars.each do |piece|
        find_field('exp-date').send_keys(piece)
      end

      cvc.chars.each do |piece|
        find_field('cvc').send_keys(piece)
      end
      zip.chars.each do |piece|
        find_field('postal').send_keys(piece)
      end
    end
  end
end
