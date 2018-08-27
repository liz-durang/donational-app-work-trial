require 'rails_helper'
require 'stripe_mock'

RSpec.describe 'Donors updates payment method', type: :feature do
  let(:stripe_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

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
    fill_in 'cardholder_name', with: 'Donatello DonatorCard'
    fill_stripe_element('4242424242424242', "01#{DateTime.now.year + 1}", '999')

    card_token = stripe_helper.generate_card_token(last4: '9191', name: 'Donatello')
    page.execute_script("document.getElementById('payment_token').value = '#{card_token}';")
    page.execute_script("document.getElementById('payment-form').submit();")
  end

  def then_credit_card_should_be_updated
    expect(page).to have_content("Thanks, we've updated your payment information")
    expect(page).to have_field(disabled:true, with: 'Donatello')
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

  def fill_stripe_element(card, exp, cvc)
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
    end
  end
end
