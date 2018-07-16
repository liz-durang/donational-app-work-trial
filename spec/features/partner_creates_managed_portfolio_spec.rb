require 'rails_helper'

RSpec.describe 'Partner creates managed portfolio', type: :feature do
  before do
    create_new_partner!
    create_organizations!
  end

  scenario 'with valid credit card', js: true do
    given_a_signed_in_partner_admin_wants_to_create_managed_portfolio
    he_fills_in_basic_portfolio_information
    he_adds_organization_to_portfolio_and_click_save
    then_managed_portfolio_should_be_created
  end

  def given_a_signed_in_partner_admin_wants_to_create_managed_portfolio
    sign_in_as!(first_name: 'Partner', last_name: 'Admin')
    # Add admin permission to edit partner
    Donor.first.partners << @partner

    visit new_partner_managed_portfolio_path(@partner)

    expect(page).to have_content('Create Portfolio')
  end

  def he_fills_in_basic_portfolio_information
    fill_in 'Title', with: 'New Portfolio'
    fill_in 'Description', with: 'New Description'
  end

  def he_adds_organization_to_portfolio_and_click_save
    page.execute_script("document.getElementById('charities').value = '#{@charity_1.name}, #{@charity_1.ein}|#{@charity_2.name}, #{@charity_2.ein}';")
    page.execute_script("document.getElementById('form').submit();")
  end

  def then_managed_portfolio_should_be_created
    sleep(2)
    expect(page).to have_content("Portfolio created successfully.")
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

  def create_new_partner!
    @partner = Partner.create(
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
  end

  def create_organizations!
    @charity_1 = create(:organization, name: 'Charity 1')
    @charity_2 = create(:organization, name: 'Charity 2')
  end
end
