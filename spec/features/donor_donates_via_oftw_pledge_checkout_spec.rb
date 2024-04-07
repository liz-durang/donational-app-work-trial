require 'rails_helper'

# Note that I think the test relies on a real internet request to load the Stripe JS library.
RSpec.describe 'Donor makes a pledge from the OFTW pledge checkout', type: :feature do
  include ActiveSupport::Testing::TimeHelpers

  let(:thank_you_url) { 'https://www.google.com/' }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:stripe_checkout_session) do
    checkout_session = stripe_helper.create_checkout_session
    customer_details_double = double('customer details')
    allow(checkout_session).to receive(:customer_details).and_return(customer_details_double)
    allow(customer_details_double).to receive(:email).and_return(stripe_customer.email)
    checkout_session
  end
  let(:stripe_setup_intent) { Stripe::SetupIntent.create }
  let(:stripe_customer) { Stripe::Customer.create(name: 'Robert Doe') }
  let(:stripe_payment_method) do
    payment_method = Stripe::PaymentMethod.create(type: 'card')
    # Note that Stripe Ruby Mock only allows 'card', 'ideal', and 'sepa_debit' payment method types, so we must stub
    # the type we want the payment method to self-report as, and related attributes.
    allow(payment_method).to receive(:type).and_return(stripe_payment_method_type)
    allow(payment_method).to receive(:[]).and_call_original # Default stub
    allow(payment_method).to receive(:[]).with(:type).and_return(stripe_payment_method_type)
    allow(payment_method).to receive(:[]).with('type').and_return(stripe_payment_method_type)
    allow(payment_method).to receive(:[]).with(stripe_payment_method_type.to_sym).and_return({ bank_name: 'Test Bank',
                                                                                               last4: '3456',
                                                                                               brand: 'Visa' })
    allow(payment_method).to receive(:[]).with(stripe_payment_method_type).and_return({ bank_name: 'Test Bank',
                                                                                        last4: '3456',
                                                                                        brand: 'Visa' })
    payment_method
  end
  let(:capybara_host) { "#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}" }

  let!(:us_partner) { create_new_partner!(currency: 'usd', name: 'Seeded/test OFTW US', thank_you_url:) }
  let!(:uk_partner) { create_new_partner!(currency: 'gbp', name: 'Seeded/test OFTW UK', thank_you_url:) }
  let!(:can_partner) do
    create_new_partner!(currency: 'cad', name: 'Seeded/test OFTW Canada', thank_you_url:)
  end
  let!(:aus_partner) do
    create_new_partner!(currency: 'aud', name: 'Seeded/test OFTW Australia', thank_you_url:)
  end

  context 'when mocking Stripe' do
    before do
      StripeMock.start
      # Mimic the use of 'expand' on the mock Checkout Session:
      allow(Stripe::Checkout::Session).to receive(:retrieve) { |arguments|
        expect(arguments[:id]).to eq(stripe_checkout_session.id)
      }.and_return(stripe_checkout_session)
      allow(stripe_checkout_session).to receive(:customer).and_return(stripe_customer)
      allow(stripe_checkout_session).to receive(:setup_intent).and_return(stripe_setup_intent)
      allow(stripe_setup_intent).to receive(:payment_method).and_return(stripe_payment_method)

      allow(stripe_checkout_session).to receive(:metadata).and_return(stripe_metadata)
    end

    after { StripeMock.stop }

    context 'when setting up a subscription to pay by UK bank debit' do
      let(:stripe_payment_method_type) { 'bacs_debit' }
      let(:unpopular_uk_portfolio) { ManagedPortfolio.find_by(name: "Unpopular Picks for #{uk_partner.name}") }
      let(:stripe_metadata) do
        {
          'estimated_future_annual_income' => '10000',
          'house_name_or_number' => 'Lake View',
          'managed_portfolio_id' => unpopular_uk_portfolio.id,
          'partner_id' => uk_partner.id,
          'payment_method_id' => 'bacs_debit',
          'pledge_percentage' => '3',
          'postcode' => 'N10 2JS',
          'start_at_month' => I18n.l(Time.zone.today, format: '%B'),
          'start_at_year' => (Time.zone.today.year + 1).to_s,
          'start_pledge_in_future' => 1,
          'title' => 'Sir',
          'trial_amount_dollars' => '',
          'uk_gift_aid_accepted' => 1
        }
      end
      let!(:donor_with_same_email_address) { create(:donor, email: stripe_customer.email) }

      it 'can create a subscription' do
        # Using the 'review_x' urls in the test environment because using subdomains in the test environment
        # proved too difficult.
        visit review_take_the_pledge_path

        expect(page).to have_content 'Step 1'
        select 'GBP', from: 'pledge_form_partner_id'
        expect(page).to have_content "Top Picks for #{uk_partner.name}"
        expect(page).not_to have_content "Top Picks for #{us_partner.name}"
        # Test that portfolios are unselected when user changes currency
        find("[data-radio-select-value='#{unpopular_uk_portfolio.id}']").click

        select 'USD', from: 'pledge_form_partner_id'
        expect(page).not_to have_content "Top Picks for #{uk_partner.name}"
        expect(page).to have_content "Top Picks for #{us_partner.name}"
        expect(page).to have_content "Unpopular Picks for #{us_partner.name}"
        expect("Top Picks for #{us_partner.name}").to appear_before("Unpopular Picks for #{us_partner.name}")
        expect(page).not_to have_content 'Managed Portfolio that has been hidden'
        expect(page).to have_content 'Managed Portfolio that has not been featured'
        click_next
        expect(page).to have_content 'Step 1'
        expect(page).to have_content 'Please choose a nonprofit by clicking on a card below'

        unpopular_us_portfolio = ManagedPortfolio.find_by(name: "Unpopular Picks for #{us_partner.name}")
        find("[data-radio-select-value='#{unpopular_us_portfolio.id}']").click

        click_next

        expect(page).to have_content 'Step 2'
        expect(page).to have_content '$'
        expect(page).not_to have_content '£'
        expect(page).not_to have_content 'Gift Aid'
        click_on 'Return'
        expect(page).to have_content 'Step 1'
        select 'GBP', from: 'pledge_form_partner_id'
        find("[data-radio-select-value='#{unpopular_uk_portfolio.id}']").click
        click_next
        expect(page).not_to have_content '$'
        expect(page).not_to have_content 'Your donation will be'
        expect(page).to have_content '£'
        expect(page).to have_content 'Gift Aid'

        fill_in 'Enter your estimated future annual income', with: 10_000
        click_on '1%'
        expect(page).to have_content 'Your donation will be £8/month'
        click_next
        expect(page).to have_content 'Step 2'
        expect(page).to have_content "The minimum monthly donation is £#{SubscriptionsController::DEFAULT_MINIMUM_CONTRIBUTION}"
        click_on '3%'
        expect(page).to have_content 'Your donation will be £25/month'

        expect(page).not_to have_content 'Year'
        expect(page).not_to have_content 'Would you like to donate a small monthly amount in the meantime?'
        check 'Start my pledge in the future'
        expect(page).to have_content 'Year'
        expect(page).to have_content 'Would you like to donate a small monthly amount in the meantime?'
        click_next
        expect(page).to have_content 'Step 2'
        expect(page).to have_content 'Please select a date'

        select I18n.l(Time.zone.today, format: '%B'), from: 'pledge_form_start_at_month'
        select Time.zone.today.year, from: 'pledge_form_start_at_year'
        click_next
        expect(page).to have_content 'Step 2'
        expect(page).to have_content 'Please select a date in the future'
        select Time.zone.today.year + 1, from: 'pledge_form_start_at_year'

        expect(page).not_to have_content 'Post code'
        check 'Yes, I am a UK taxpayer'
        expect(page).to have_content 'Post code'
        click_next
        expect(page).to have_content 'Step 2'
        expect(page).to have_content 'Please enter your title'
        expect(page).to have_content 'Please enter your house name or number'
        expect(page).to have_content 'Please enter a valid UK postcode'

        fill_in 'Title', with: 'Sir'
        fill_in 'House name/number', with: 'Lake View'
        fill_in 'Post code', with: 'N10 2JS'
        click_next
        expect(page).to have_content 'Step 3'

        # Test that bank payment is pre-selected
        expect(find('.is-active')).to have_content 'Direct Debit'

        # One important thing this expectation verifies is that the correct form inputs from the first several
        # steps of the form are passed along to Stripe as 'metadata' to be parsed after the Stripe checkout completes.
        expect(Stripe::Checkout::Session).to receive(:create).with(
          { mode: 'setup',
            success_url: review_take_the_pledge_url(host: capybara_host, stripe_session_id: '{CHECKOUT_SESSION_ID}',
                                                    partner_id: uk_partner.id).gsub('%7B', '{').gsub('%7D', '}'),
            cancel_url: review_take_the_pledge_url(host: capybara_host),
            customer_creation: 'always',
            currency: 'gbp',
            payment_method_options: {},
            payment_method_types: ['bacs_debit'],
            metadata: stripe_metadata }, { stripe_account: uk_partner.payment_processor_account_id }
        ).and_return(stripe_checkout_session)

        click_next

        sleep 3 # Allow time for the redirect to take place

        # Expect the user to automatically be redirected to Stripe.
        expect(page.current_url).to eq(stripe_checkout_session.url)

        visit review_take_the_pledge_path(stripe_session_id: stripe_checkout_session.id, partner_id: uk_partner.id)
        expect(page).to have_content('Step 4 of 5')
        expect(find_field('First name').value).to eq 'Robert'
        expect(find_field('Last name').value).to eq 'Doe'
        expect(find_field('Email').value).to eq stripe_customer.email
        expect(page).not_to have_content('Enter your chapter name')
        fill_in('First name', with: 'Bob', fill_options: { clear: :backspace })
        fill_in('Last name', with: '', fill_options: { clear: :backspace })
        fill_in('Email', with: 'invalid', fill_options: { clear: :backspace })
        uncheck 'One for the World has final say on donation allocation'

        find('.button', text: 'Continue to summary').click
        expect(page).to have_content('Step 4 of 5')
        expect(page).to have_content('Please enter your last name')
        expect(page).to have_content('Please enter a valid email address')
        expect(page).to have_content('This field is required').exactly(3).times
        expect(page).to have_content('Please acknowledge the above')

        within('#associated_with_chapter') do
          find('.button', text: 'Yes').click
        end
        expect(page).to have_content('Enter your chapter name')
        find('.button', text: 'Continue to summary').click
        expect(page).to have_content('Step 4 of 5')
        expect(page).to have_content('Please enter your chapter')

        fill_in('Last name', with: 'Doe')
        fill_in('Email', with: stripe_customer.email)

        # Without `sleep`s, the telephone field JS makes this test somewhat flakey with regards to successfully populating
        # the hidden phone_number field in interaction with Capybara, but it works fine in the
        # browser when operated by a human.
        sleep 1
        fill_in('Mobile phone', with: '07123 456789')
        sleep 1
        fill_in('Enter your chapter name', with: 'A chapter that is not in the dropdown list')
        check 'One for the World has final say on donation allocation'
        within('#givewell_familiar') do
          find('.button', text: 'Yes').click
        end

        select 'September', from: 'pledge_form_birthday_2i'
        select '25', from: 'pledge_form_birthday_3i'
        check 'Yes, sign me up for email updates'
        check 'Yes, sign me up for SMS updates'

        find('.button', text: 'Continue to summary').click
        expect(page).to have_content('I pledge 3% of my income to fight extreme poverty.')
        expect(page).to have_content('£25/month')
        expect(page).to have_content("#{I18n.l(Time.zone.today, format: '%B')} 15, #{Time.zone.today.year + 1}")
        expect(page).not_to have_content('Trial')

        expect do
          find('.button', text: 'Submit my pledge').click
        end.to change { Donor.count }.by(0).and change { Subscription.count }.by(0)

        expect(page).to have_content('Step 4 of 5')
        expect(page).to have_content('This email address has already been used')
        fill_in('Email', with: 'my_personal_email@example.com')
        # Without `sleep`s, the telephone field JS makes this test somewhat flakey with regards to successfully populating
        # the hidden phone_number field in interaction with Capybara, but it works fine in the
        # browser when operated by a human.
        sleep 1
        fill_in('Mobile phone', with: '07123 456789')
        sleep 1
        fill_in('Enter your chapter name', with: 'A chapter that is not in the dropdown list')
        check 'One for the World has final say on donation allocation'
        within('#givewell_familiar') do
          find('.button', text: 'Yes').click
        end
        select 'September', from: 'pledge_form_birthday_2i'
        select '25', from: 'pledge_form_birthday_3i'
        check 'Yes, sign me up for email updates'
        check 'Yes, sign me up for SMS updates'
        find('.button', text: 'Continue to summary').click
        expect(page).to have_content('I pledge 3% of my income to fight extreme poverty.')
        expect(page).to have_content('£25/month')
        expect(page).to have_content("#{I18n.l(Time.zone.today, format: '%B')} 15, #{Time.zone.today.year + 1}")
        expect(page).not_to have_content('Trial')

        expect do
          find('.button', text: 'Submit my pledge').click
        end.to change { Donor.count }.by(1).and change { Subscription.count }.by(1)

        expect(page.current_url).to eq(thank_you_url)

        donor = Donor.find_by(
          contribution_frequency: 'monthly',
          uk_gift_aid_accepted: true,
          first_name: 'Bob',
          last_name: 'Doe',
          email: 'my_personal_email@example.com',
          title: 'Sir',
          house_name_or_number: 'Lake View',
          postcode: 'N10 2JS',
          annual_income_cents: 1_000_000
        )
        expect(Partners::GetPartnerForDonor.call(donor:)).to eq(uk_partner)
        expect(Portfolios::GetActivePortfolio.call(donor:)).to eq(unpopular_uk_portfolio.portfolio)
        expect(Payments::GetActivePaymentMethod.call(donor:)).to have_attributes(
          donor:,
          payment_processor_customer_id: stripe_customer.id,
          type: PaymentMethods::BacsDebit.to_s,
          last4: '3456',
          name: 'John Dolton', # Default provided by Stripe Ruby Mock
          institution: 'Test Bank',
          address_zip_code: '10000', # Default provided by Stripe Ruby Mock
          payment_processor_source_id: stripe_payment_method.id
        )
        partner_affiliation = Partners::GetPartnerAffiliationByDonor.call(donor:)
        expect(partner_affiliation.campaign).to be_blank
        expect(partner_affiliation.custom_donor_info).to include({ 'chapter' => 'A chapter that is not in the dropdown list',
                                                                   'comms_email' => '1',
                                                                   'comms_phone' => '1',
                                                                   'birthday_month' => '9',
                                                                   'birthday_day' => '25',
                                                                   'phone_number' => '+447123456789',
                                                                   'givewell_comms' => '1',
                                                                   'OFTW_discretion' => '1',
                                                                   'nonprofit_comms' => '1',
                                                                   'givewell_familiar' => 'true' })

        expect(Subscription.order(created_at: :desc).first).to have_attributes(
          start_at: Time.zone.local(Time.zone.today.year + 1, Time.zone.today.month, 15, 12, 0),
          portfolio: unpopular_uk_portfolio.portfolio,
          partner: uk_partner,
          frequency: 'monthly',
          amount_cents: 2500,
          amount_currency: 'gbp',
          tips_cents: 0,
          partner_contribution_percentage: 0,
          trial_start_at: nil,
          trial_last_scheduled_at: nil,
          trial_deactivated_at: nil,
          trial_amount_cents: 0
        )
      end
    end

    context 'when setting up a subscription to pay by card' do
      let(:stripe_payment_method_type) { 'card' }
      let(:popular_us_portfolio) { ManagedPortfolio.find_by(name: "Top Picks for #{us_partner.name}") }

      context 'with a trial subscription' do
        let(:stripe_metadata) do
          {
            'estimated_future_annual_income' => '10000',
            'house_name_or_number' => '',
            'managed_portfolio_id' => popular_us_portfolio.id,
            'partner_id' => us_partner.id,
            'payment_method_id' => 'card',
            'pledge_percentage' => '5',
            'postcode' => '',
            'start_at_month' => I18n.l(Time.zone.today, format: '%B'),
            'start_at_year' => (Time.zone.today.year + 1).to_s,
            'start_pledge_in_future' => 1,
            'title' => '',
            'trial_amount_dollars' => '123',
            'uk_gift_aid_accepted' => 0
          }
        end

        before { freeze_time }

        it 'can set a trial subscription' do
          visit review_take_the_pledge_path
          select 'USD', from: 'pledge_form_partner_id'
          find("[data-radio-select-value='#{popular_us_portfolio.id}']").click
          click_next
          fill_in 'Enter your estimated future annual income', with: 10_000
          click_on '5%'
          expect(page).not_to have_content 'Would you like to donate a small monthly amount in the meantime?'
          check 'Start my pledge in the future'
          expect(page).to have_content 'Would you like to donate a small monthly amount in the meantime?'
          select I18n.l(Time.zone.today, format: '%B'), from: 'pledge_form_start_at_month'
          select Time.zone.today.year + 1, from: 'pledge_form_start_at_year'
          fill_in('pledge_form_trial_amount_dollars', with: '123')
          click_next

          # Test that bank payment is pre-selected
          expect(find('.is-active')).to have_content 'Direct Debit'
          find("[data-radio-select-value='card']").click

          # One important thing this expectation verifies is that the correct form inputs from the first several
          # steps of the form are passed along to Stripe as 'metadata' to be parsed after the Stripe checkout completes.
          expect(Stripe::Checkout::Session).to receive(:create).with(
            { mode: 'setup',
              success_url: review_take_the_pledge_url(host: capybara_host, stripe_session_id: '{CHECKOUT_SESSION_ID}',
                                                      partner_id: us_partner.id).gsub('%7B', '{').gsub('%7D', '}'),
              cancel_url: review_take_the_pledge_url(host: capybara_host),
              customer_creation: 'always',
              currency: 'usd',
              payment_method_options: {},
              payment_method_types: ['card'],
              metadata: stripe_metadata }, { stripe_account: uk_partner.payment_processor_account_id }
          ).and_return(stripe_checkout_session)

          click_next

          sleep 3 # Allow time for the redirect to take place

          # Expect the user to automatically be redirected to Stripe.
          expect(page.current_url).to eq(stripe_checkout_session.url)

          visit review_take_the_pledge_path(stripe_session_id: stripe_checkout_session.id, partner_id: us_partner.id)

          # Without `sleep`s, the telephone field JS makes this test somewhat flakey with regards to successfully populating
          # the hidden phone_number field in interaction with Capybara, but it works fine in the
          # browser when operated by a human.
          sleep 1
          fill_in('Mobile phone', with: '(201) 555-0123')
          sleep 1
          within('#associated_with_chapter') do
            find('.button', text: 'No').click
          end
          within('#givewell_familiar') do
            find('.button', text: 'No').click
          end

          find('.button', text: 'Continue to summary').click
          expect(page).to have_content('I pledge 5% of my income to fight extreme poverty.')
          expect(page).to have_content('$42/month')
          expect(page).to have_content("#{I18n.l(Time.zone.today, format: '%B')} 15, #{Time.zone.today.year + 1}")
          expect(page).to have_content('Trial amount')
          expect(page).to have_content('$123/month')
          expect(page).to have_content("#{I18n.l(next_fifteenth, format: '%B')} 15, #{next_fifteenth.year}")

          expect do
            find('.button', text: 'Submit my pledge').click
          end.to change { Donor.count }.by(1).and change { Subscription.count }.by(1)

          expect(page.current_url).to eq(thank_you_url)

          donor = Donor.find_by(
            contribution_frequency: 'monthly',
            uk_gift_aid_accepted: false,
            first_name: 'Robert',
            last_name: 'Doe',
            email: 'stripe_mock@example.com',
            title: '',
            house_name_or_number: '',
            postcode: '',
            annual_income_cents: 1_000_000
          )
          expect(Partners::GetPartnerForDonor.call(donor:)).to eq(us_partner)
          expect(Portfolios::GetActivePortfolio.call(donor:)).to eq(popular_us_portfolio.portfolio)
          expect(Payments::GetActivePaymentMethod.call(donor:)).to have_attributes(
            donor:,
            payment_processor_customer_id: stripe_customer.id,
            type: PaymentMethods::Card.to_s,
            last4: '3456',
            name: 'John Dolton', # Default provided by Stripe Ruby Mock
            institution: 'Visa',
            address_zip_code: '10000', # Default provided by Stripe Ruby Mock
            payment_processor_source_id: stripe_payment_method.id
          )
          partner_affiliation = Partners::GetPartnerAffiliationByDonor.call(donor:)
          expect(partner_affiliation.campaign).to be_blank
          expect(partner_affiliation.custom_donor_info).to include({ 'chapter' => 'N/A',
                                                                     'comms_email' => '0',
                                                                     'comms_phone' => '0',
                                                                     'birthday_month' => '',
                                                                     'birthday_day' => '',
                                                                     'phone_number' => '+12015550123',
                                                                     'givewell_comms' => '1',
                                                                     'OFTW_discretion' => '1',
                                                                     'nonprofit_comms' => '1',
                                                                     'givewell_familiar' => 'false' })

          expect(Subscription.last).to have_attributes(
            start_at: Time.zone.local(Time.zone.today.year + 1, Time.zone.today.month, 15, 12, 0),
            portfolio: popular_us_portfolio.portfolio,
            partner: us_partner,
            frequency: 'monthly',
            amount_cents: 4200,
            amount_currency: 'usd',
            tips_cents: 0,
            partner_contribution_percentage: 0,
            trial_start_at: Time.zone.now,
            trial_last_scheduled_at: nil,
            trial_deactivated_at: nil,
            trial_amount_cents: 12_300
          )
        end
      end
    end

    context 'when pledging from a campaign' do
      let(:stripe_payment_method_type) { 'acss_debit' }
      let(:popular_canada_portfolio) { ManagedPortfolio.find_by(name: "Top Picks for #{can_partner.name}") }
      let(:stripe_metadata) do
        {
          'estimated_future_annual_income' => '10000',
          'house_name_or_number' => '',
          'managed_portfolio_id' => popular_canada_portfolio.id,
          'partner_id' => can_partner.id,
          'payment_method_id' => 'acss_debit',
          'pledge_percentage' => '5',
          'postcode' => '',
          'start_at_month' => '',
          'start_at_year' => '',
          'start_pledge_in_future' => 0,
          'title' => '',
          'trial_amount_dollars' => '',
          'uk_gift_aid_accepted' => 0
        }
      end
      # Using a campaign linked to the UK partner in order to test that the resulting associations to partner are
      # determined by the user's choice of currency and not by the campaign's association to a partner.
      let(:uk_campaign) do
        Campaigns::CreateCampaign.run(
          partner: uk_partner,
          slug: 'cam-uni',
          minimum_contribution_amount: 40,
          title: 'Cambridge',
          contribution_amount_help_text: 'The average Cambridge University graduate donates £12,345.67 a year.',
          default_contribution_amounts: [40, 41, 42], # Not used in flow, but required by CreateCampaign command
          allow_one_time_contributions: true
        )
        Partners::GetCampaignBySlug.call(slug: 'cam-uni')
      end

      before { freeze_time }

      it 'alters the flow per campaign' do
        visit review_campaign_take_the_pledge_path(campaign_slug: uk_campaign.slug)

        expect(find_by_id('pledge_form_partner_id').value).to eq uk_campaign.partner_id

        select 'CAD', from: 'pledge_form_partner_id'
        find("[data-radio-select-value='#{popular_canada_portfolio.id}']").click
        click_next

        # Test that the contribution_amount_help_text is set by the campaign and is not the default.
        expect(page).to have_content('The average Cambridge University graduate donates £12,345.67 a year.')
        fill_in 'Enter your estimated future annual income', with: 10_000
        click_on '3%'
        # Test that the minimum_contribution_amount is set by the campaign and is not the default ($20).
        click_next
        expect(page).to have_content('Step 2 of 5')
        expect(page).to have_content('The minimum monthly donation is $40')
        click_on '5%'
        click_next

        # Test that bank payment is pre-selected
        expect(find('.is-active')).to have_content 'Direct Debit'

        # One important thing this expectation verifies is that the correct form inputs from the first several
        # steps of the form are passed along to Stripe as 'metadata' to be parsed after the Stripe checkout completes.
        expect(Stripe::Checkout::Session).to receive(:create).with(
          { mode: 'setup',
            success_url: review_campaign_take_the_pledge_url(host: capybara_host, stripe_session_id: '{CHECKOUT_SESSION_ID}',
                                                             partner_id: can_partner.id, campaign_slug: uk_campaign.slug).gsub('%7B', '{').gsub('%7D', '}'),
            cancel_url: review_campaign_take_the_pledge_url(host: capybara_host, campaign_slug: uk_campaign.slug),
            customer_creation: 'always',
            currency: 'cad',
            payment_method_options: { acss_debit: {
              currency: 'cad',
              mandate_options: {
                payment_schedule: 'interval',
                interval_description: 'on the 15th of every month',
                transaction_type: 'personal'
              }
            } },
            payment_method_types: ['acss_debit'],
            metadata: stripe_metadata }, { stripe_account: can_partner.payment_processor_account_id }
        ).and_return(stripe_checkout_session)

        click_next

        sleep 3 # Allow time for the redirect to take place

        # Expect the user to automatically be redirected to Stripe.
        expect(page.current_url).to eq(stripe_checkout_session.url)

        visit review_campaign_take_the_pledge_path(stripe_session_id: stripe_checkout_session.id,
                                                   partner_id: can_partner.id, campaign_slug: uk_campaign.slug)

        # Without `sleep`s, the telephone field JS makes this test somewhat flakey with regards to successfully populating
        # the hidden phone_number field in interaction with Capybara, but it works fine in the
        # browser when operated by a human.
        sleep 1
        find('.iti__flag-container').click # Test whether we store the correct country code.
        find('.iti__country-name', text: 'Afghanistan').click # Afghan country code is 93.
        fill_in('Mobile phone', with: '070 123 4567')
        sleep 1

        # Test that we don't ask the unnecessary question of chapter affiliation (inferred from campaign)
        expect(page).not_to have_content('Enter your chapter name')
        within('#givewell_familiar') do
          find('.button', text: 'No').click
        end

        find('.button', text: 'Continue to summary').click
        expect(page).to have_content('I pledge 5% of my income to fight extreme poverty.')
        expect(page).to have_content('$42/month')
        expect(page).to have_content("#{I18n.l(next_fifteenth, format: '%B')} 15, #{next_fifteenth.year}")
        expect(page).not_to have_content('Trial amount')

        expect do
          find('.button', text: 'Submit my pledge').click
        end.to change { Donor.count }.by(1).and change { Subscription.count }.by(1)

        expect(page.current_url).to eq(thank_you_url)

        donor = Donor.find_by(
          contribution_frequency: 'monthly',
          uk_gift_aid_accepted: false,
          first_name: 'Robert',
          last_name: 'Doe',
          email: 'stripe_mock@example.com',
          title: '',
          house_name_or_number: '',
          postcode: '',
          annual_income_cents: 1_000_000
        )

        # Test that the resulting associations to partner are determined by the choice of
        # currency and not by the campaign's association to a partner.
        expect(Partners::GetPartnerForDonor.call(donor:)).to eq(can_partner)
        expect(Portfolios::GetActivePortfolio.call(donor:)).to eq(popular_canada_portfolio.portfolio)
        expect(Payments::GetActivePaymentMethod.call(donor:)).to have_attributes(
          donor:,
          payment_processor_customer_id: stripe_customer.id,
          type: PaymentMethods::AcssDebit.to_s,
          last4: '3456',
          name: 'John Dolton', # Default provided by Stripe Ruby Mock
          institution: 'Test Bank',
          address_zip_code: '10000', # Default provided by Stripe Ruby Mock
          payment_processor_source_id: stripe_payment_method.id
        )
        partner_affiliation = Partners::GetPartnerAffiliationByDonor.call(donor:)
        expect(partner_affiliation.campaign).to eq(uk_campaign)
        # Test that of the list of chapters (which is a hidden dropdown in the case of
        # the campaign-specific flow), the chapter with a name similar to the name of the campaign is
        # automatically selected and stored against the custom donor information (and that we store the slug rather
        # than the title of the campaign)
        expect(partner_affiliation.custom_donor_info).to include({ 'chapter' => uk_campaign.slug,
                                                                   'comms_email' => '0',
                                                                   'comms_phone' => '0',
                                                                   'birthday_month' => '',
                                                                   'birthday_day' => '',
                                                                   'phone_number' => '+93701234567',
                                                                   'givewell_comms' => '1',
                                                                   'OFTW_discretion' => '1',
                                                                   'nonprofit_comms' => '1',
                                                                   'givewell_familiar' => 'false' })
        expect(Subscription.last).to have_attributes(
          start_at: Time.zone.now,
          portfolio: popular_canada_portfolio.portfolio,
          partner: can_partner,
          frequency: 'monthly',
          amount_cents: 4200,
          amount_currency: 'cad',
          tips_cents: 0,
          partner_contribution_percentage: 0,
          trial_start_at: nil,
          trial_last_scheduled_at: nil,
          trial_deactivated_at: nil,
          trial_amount_cents: 0
        )
      end
    end

    def create_new_partner!(currency:, name:, thank_you_url:)
      one_for_the_world_operating_costs_charity = create(:organization, name: 'OFTW Operating Costs')

      partner = Partner.create(
        name:,
        currency:,
        platform_fee_percentage: 0.02,
        after_donation_thank_you_page_url: thank_you_url,
        donor_questions_schema: {
          questions: [{ 'name' => 'phone_number',
                        'type' => 'text',
                        'title' => 'Mobile phone',
                        'options' => [],
                        'required' => true },
                      { 'name' => 'comms_email',
                        'type' => 'checkbox',
                        'title' => 'Yes, sign me up for email updates',
                        'options' => [],
                        'required' => false },
                      { 'name' => 'comms_phone',
                        'type' => 'checkbox',
                        'title' => 'Yes, sign me up for SMS updates',
                        'options' => [],
                        'required' => false },
                      { 'name' => 'birthday',
                        'type' => 'date',
                        'title' => 'When is your birthday?',
                        'options' => [],
                        'required' => false },
                      { 'name' => 'chapter',
                        'type' => 'select',
                        'title' => 'Enter your chapter name',
                        'options' => ['N/A', 'Example chapter 1', 'Example chapter 2', 'Cambridge University', 'Other'],
                        'required' => true },
                      { 'name' => 'givewell_familiar',
                        'type' => 'select',
                        'title' => "Were you familiar with GiveWell's recommended nonprofits before you encountered One for the World?",
                        'options' => %w[Yes No],
                        'required' => true },
                      { 'name' => 'nonprofit_comms',
                        'type' => 'checkbox',
                        'title' => 'Share my name, contact info, and donation info with <b>the nonprofits I support</b>, so that they can email me and track their donations better',
                        'options' => [],
                        'required' => false },
                      { 'name' => 'givewell_comms',
                        'type' => 'checkbox',
                        'title' =>
                      'Share my name, contact info, and donation info with <b>GiveWell</b> so that they can email me and track their donations better',
                        'options' => [],
                        'required' => false },
                      { 'name' => 'OFTW_discretion',
                        'type' => 'checkbox',
                        'title' =>
                      'Just like other regranting nonprofits, One for the World has final say on donation allocation. We follow member preferences and will inform you before redirecting donations, if our recommended nonprofits change.',
                        'options' => [],
                        'required' => true }]
        },
        operating_costs_text: 'For every $1 donated to One for the World, we raise $12 for effective charities. Please select here if you are happy for some of your donations to go to One for the World.',
        operating_costs_organization: one_for_the_world_operating_costs_charity,
        payment_processor_account_id: 'acc_123',
        uses_one_for_the_world_checkout: true
      )

      create_managed_portfolios_for_partner!(partner)

      partner
    end

    def create_managed_portfolios_for_partner!(partner)
      charity_1 = create(:organization, name: 'Charity 1')
      charity_2 = create(:organization, name: 'Charity 2')
      portfolio = create(:portfolio)
      Portfolios::AddOrganizationsAndRebalancePortfolio.run(
        portfolio:, organization_eins: [charity_1.ein, charity_2.ein]
      )
      ManagedPortfolio.create(
        partner:,
        portfolio:,
        name: "Unpopular Picks for #{partner.name}",
        featured: true,
        display_order: 2
      )
      ManagedPortfolio.create(
        partner:,
        portfolio:,
        name: "Top Picks for #{partner.name}",
        featured: true,
        display_order: 1
      )
      ManagedPortfolio.create(
        partner:,
        portfolio:,
        name: 'Managed Portfolio that has been hidden',
        featured: true,
        hidden_at: 1.day.ago
      )
      ManagedPortfolio.create(
        partner:,
        portfolio:,
        name: 'Managed Portfolio that has not been featured',
        featured: false
      )
    end

    def click_next
      find('.button', text: 'Next ➝').click
    end

    def next_fifteenth
      if Time.zone.today.day > 15
        Time.zone.local(Time.zone.today.year, Time.zone.today.month + 1,
                        15)
      elsif Time.zone.today.day < 15
        Time.zone.local(Time.zone.today.year, Time.zone.today.month, 15)
      elsif Time.zone.today.day == 15
        Time.zone.today
      end
    end
  end
end
