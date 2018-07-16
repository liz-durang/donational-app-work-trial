require 'rails_helper'

RSpec.describe 'Donors updates payment method', type: :feature do
  scenario 'with valid credit card', js: true do
    given_a_signed_in_donor_wants_to_update_payment_method
    when_he_does_not_have_any_credit_card_added
    he_should_add_credit_card_information_and_click_save
    then_credit_card_should_be_updated
  end

  def given_a_signed_in_donor_wants_to_update_payment_method
    sign_in_as!(first_name: 'Donny', last_name: 'Donator')
    visit edit_accounts_path
  end

  def when_he_does_not_have_any_credit_card_added
    expect(page).to have_content('Donny Donator')
    expect(page).to have_content("You don't have any payment method on file. Please add your credit card using the form below.")
  end

  def he_should_add_credit_card_information_and_click_save
    fill_in 'first_name', with: 'Donatello'
    fill_in 'last_name', with: "DonatorCard"
    fill_in 'credit_card', with: '4111 1111 1111 1111'
    fill_in 'cvv', with: '999'
    select '12', from: 'month'
    select '2025', from: 'year'
    click_button 'Update card'
  end

  def then_credit_card_should_be_updated
    sleep(2)
    expect(page).to have_content("Thanks, we've updated your payment information")
    expect(page).to have_field(disabled:true, with: 'Donatello DonatorCard')
  end


  def sign_in_as!(first_name:, last_name:, email: 'user@example.com')
    OmniAuth.config.add_mock(
      :auth0,
      {
        uid: '12345', info: { email: email, first_name: first_name, last_name: last_name }
      }
    )

    visit auth_oauth2_callback_path
  end
end
