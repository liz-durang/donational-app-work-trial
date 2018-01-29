require 'rails_helper'

RSpec.describe 'Visitor signs in', type: :feature do
  scenario 'with valid credentials', js: true do
    visit new_sessions_path
    expect(page).to have_content('LOGIN WITH GOOGLE')
    sign_in_as!(first_name: 'Donny', last_name: 'Donator')
    expect(page).to have_content('Donny Donator')
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
