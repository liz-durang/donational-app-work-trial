require 'rails_helper'

RSpec.describe 'Partner uses donor console', type: :feature do
  let(:stripe_helper) { StripeMock.create_test_helper }
  before do
    StripeMock.start
    create_default_partner!
    create_new_partner!
    create_other_partner!
    create_a_bunch_of_donors!
    and_one_with_a_donation_plan!
  end
  after { StripeMock.stop }

  scenario 'with no existing donors', js: true do
    a_partner_signs_in_without_permissions
    the_partner_gets_permissions_and_goes_to_portal
    the_partner_creates_a_new_donor_without_required_fields
    the_partner_creates_a_new_donor_with_required_fields
    then_the_partner_searches_for_the_donor
    then_the_partner_edits_the_donors_city_without_required_fields
    then_the_partner_edits_the_donors_city_with_required_fields
  end

  scenario 'with existing donors, and before grants have been processed', js: true do
    other_partner_signs_in
    then_the_partner_goes_to_the_next_page_and_edits_donor
    then_the_partner_changes_the_donors_payment_method
    then_the_partner_updates_the_donation_plan
    then_the_partner_delays_the_donation_plan
    then_the_partner_cancels_the_donation_plan
    then_the_partner_refunds_an_ungranted_contribution
  end

  scenario 'with existing donors, and after grants have been processed', js: true do
    given_grants_are_processed 
    other_partner_signs_in
    then_the_partner_goes_to_the_next_page_and_edits_donor
    then_the_partner_tries_to_refund_a_granted_contribution
  end

  def a_partner_signs_in_without_permissions
    sign_in_as!(first_name: 'Partner', last_name: 'Admin')
    visit partner_donors_path(@partner)
    expect(page).to have_no_content("Partner Account")
  end

  def the_partner_gets_permissions_and_goes_to_portal
    # Add admin permission to edit partner
    Partners::AssignPartnerAdminPrivilegesToDonor.run(
      donor: Donor.find_by(email: 'user@example.com'),
      partner: @partner)
    visit partner_donors_path(@partner)
  end

  def the_partner_creates_a_new_donor_without_required_fields
    click_on 'Create Donor'
    click_on 'Save'
    expect(page).to have_content("Please fill in the required field(s)")
  end

  def the_partner_creates_a_new_donor_with_required_fields
    fill_in 'First Name', with: 'Dale'
    fill_in 'Last Name', with: 'Cooper'
    fill_in 'Email', with: 'dcooper@test.test'
    fill_in 'Which city will you be living in when your donation commences?', with: 'Twin Peaks'
    click_on 'Save'
    expect(page).to have_content("Donor Created Successfully")
  end

  def then_the_partner_searches_for_the_donor
    Donor.reindex
    fill_in 'Search', with: 'Dale'
    click_on 'Search'
    expect(page).to have_content("dcooper@test.test")
  end

  def then_the_partner_edits_the_donors_city_without_required_fields
    click_on 'Edit'
    expect(page).to have_content("Edit Donor: Dale Cooper")
    fill_in 'First Name', with: ''
    click_on 'Save'
    expect(page).to have_content("Please fill in the required field(s)")
  end

  def then_the_partner_edits_the_donors_city_with_required_fields
    fill_in 'Which city will you be living in when your donation commences?', with: 'NYC'
    click_on 'Save'
    expect(page).to have_content("Donor Updated Successfully")
  end

  def other_partner_signs_in
    sign_in_as!(first_name: 'Partner', last_name: 'Admin')
    # Add admin permission to edit partner
    Partners::AssignPartnerAdminPrivilegesToDonor.run(
      donor: Donor.find_by(email: 'user@example.com'),
      partner: @other_partner)
    visit partner_donors_path(@other_partner)
  end
  
  def then_the_partner_goes_to_the_next_page_and_edits_donor
    click_on 'Next ›'
    click_on 'Edit'
    expect(page).to have_content("Edit Donor: John Doe 11")
  end
  
  def then_the_partner_changes_the_donors_payment_method
    find('[data-accordion-trigger="update-card"]').click
    fill_in 'cardholder_name', with: 'Donatello DonatorCard'
    fill_stripe_element('4242424242424242', "01#{DateTime.now.year + 1}", '999')

    card_token = stripe_helper.generate_card_token(last4: '9191', name: 'Donatello')
    page.execute_script("document.getElementById('payment_token').value = '#{card_token}';")
    page.execute_script("document.getElementById('payment-form').submit();")
  end
  
  def then_the_partner_updates_the_donation_plan
    fill_in 'recurring_contribution[amount_dollars]', with: '100'
    find('[data-disable-with="Update donation plan"]').click
    date_in_one_month_on_the_15th = (Date.new(Date.today.year, Date.today.month, 15) + 1.month)
    expect(page).to have_content("Your next donation of $100.00 is scheduled for #{date_in_one_month_on_the_15th.to_formatted_s(:long_ordinal)}")
  end
  
  def then_the_partner_delays_the_donation_plan
    find('[data-target="ask-to-pause-modal"]').click
    within('#ask-to-pause-modal') do
      find('[value="Sounds great!"]').click
    end
    date_in_three_months = (Date.today + 3.months)
    expect(page).to have_content("Your next donation of $100.00 is scheduled for #{date_in_three_months.to_formatted_s(:long_ordinal)}")
  end
  
  def then_the_partner_cancels_the_donation_plan
    find('[data-target="ask-to-pause-modal"]').click
    within('#ask-to-pause-modal') do
      click_on 'No, I still want to cancel'
    end
    expect(page).to have_content("We've cancelled the donation plan")
  end

  def then_the_partner_refunds_an_ungranted_contribution
    click_on 'Refund'
    page.accept_alert
    expect(page).to have_content("Contribution Refunded Successfully")
  end

  def given_grants_are_processed
    Grants::ScheduleGrant.run
  end

  def then_the_partner_tries_to_refund_a_granted_contribution
    click_on 'Refund'
    page.accept_alert
    expect(page).to have_content("This contribution could not be refunded, as it has already been assigned to one or more grants to organizations")
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

  def create_default_partner!
    create(:partner, :default)
  end

  def create_new_partner!
    @partner = Partner.create(
      name: 'One for the World',
      currency: 'usd',
      platform_fee_percentage: 0.02,
      payment_processor_account_id: 'acc_123',
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

  def create_other_partner!
    @other_partner = Partner.create(
      name: 'Other One for the World',
      currency: 'usd',
      platform_fee_percentage: 0.02,
      payment_processor_account_id: 'acc_123',
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

  def create_a_bunch_of_donors!
    (11).downto(1) do |i|
      num = i.to_s
      create(:donor, first_name: 'John', last_name: 'Doe ' + num, email: num + '@test.test')
      Partners::AffiliateDonorWithPartner.run(partner: @other_partner, donor: Donor.find_by(email: num + '@test.test'))
    end
  end

  def and_one_with_a_donation_plan!
    target_donor = Donor.find_by(email: '11@test.test')
    create(:portfolio)
    create(:allocation, portfolio: Portfolio.first, organization: create(:organization, ein: 'org1'), percentage: 60)
    create(:allocation, portfolio: Portfolio.first, organization: create(:organization, ein: 'org2'), percentage: 40)
    Payments::UpdatePaymentMethod.run(
      donor: target_donor,
      payment_token: stripe_helper.generate_card_token({
        number: '4242424242424242',
        exp_month: 12,
        exp_year: 1.year.from_now.year,
        cvc: '999'
      })
    )
    Contributions::CreateOrReplaceRecurringContribution.run({
      donor: target_donor,
      portfolio: Portfolio.first,
      partner: @other_partner,
      amount_cents: 8000,
      tips_cents: 100,
      frequency: :monthly,
      start_at: Time.zone.now
    })
    ScheduleContributionsForPastDuePlans.new.perform
    ProcessScheduledContributions.new.perform
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
