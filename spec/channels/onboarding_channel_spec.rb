# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingChannel, type: :channel do
  let(:donor) { create(:donor) }
  let(:room_id) { 'test-room-123' }

  # Mock wizard and steps
  let(:mock_wizard) { instance_double(Wizard) }
  let(:mock_step) { double('Step') }
  let(:mock_previous_step) { double('Step') }
  let(:null_step) { instance_double(NullStep) }

  # Mock onboarding steps
  let(:are_you_ready_step) { instance_double('Onboarding::AreYouReady') }
  let(:first_name_step) { instance_double('Onboarding::WhatIsYourFirstName') }
  let(:email_step) { instance_double('Onboarding::WhatIsYourEmail') }

  # Setup proper channel connection using Rails testing approach
  let(:connection) do
    # Create a connection instance with the current_donor identifier
    connection_instance = ApplicationCable::Connection.allocate
    
    # Set up logger
    test_logger = ActiveSupport::Logger.new(StringIO.new)
    tagged_logger = ActiveSupport::TaggedLogging.new(test_logger)
    connection_instance.instance_variable_set(:@logger, tagged_logger)
    
    # Set up the current_donor identifier
    connection_instance.instance_variable_set(:@current_donor, donor)
    def connection_instance.current_donor
      @current_donor
    end
    
    connection_instance
  end
  
  let(:channel) do
    # Create channel instance with proper connection
    channel_instance = OnboardingChannel.allocate
    channel_instance.instance_variable_set(:@connection, connection)
    channel_instance.instance_variable_set(:@params, { 'room' => room_id })
    channel_instance.instance_variable_set(:@identifier, { 'channel' => 'OnboardingChannel', 'room' => room_id }.to_json)
    
    # Define required ActionCable methods
    def channel_instance.stream_for(identifier)
      # Mock implementation for testing
    end
    
    def channel_instance.params
      @params
    end
    
    def channel_instance.current_donor
      @connection.current_donor
    end
    
    channel_instance
  end

  before do
    # Mock Wizard methods
    allow(mock_wizard).to receive(:restart!)
    allow(mock_wizard).to receive(:current_step).and_return(mock_step)
    allow(mock_wizard).to receive(:previous_step).and_return(mock_previous_step)
    allow(mock_wizard).to receive(:process_step!)
    allow(mock_wizard).to receive(:finished?).and_return(false)

    # Mock step methods
    allow(mock_step).to receive(:display_as).and_return('radio_buttons')
    allow(mock_step).to receive(:class).and_return('MockStep')
    allow(mock_step).to receive(:follow_up_messages).and_return([])
    allow(mock_step).to receive(:error_messages).and_return([])
    allow(mock_step).to receive(:messages).and_return([])
    allow(mock_step).to receive(:heading).and_return('Test heading')

    # Mock previous step methods
    allow(mock_previous_step).to receive(:follow_up_messages).and_return([])
    allow(mock_previous_step).to receive(:error_messages).and_return([])
    allow(mock_previous_step).to receive(:messages).and_return([])
    allow(mock_previous_step).to receive(:heading).and_return('Previous heading')

    # Mock all onboarding step classes
    allow(Onboarding::AreYouReady).to receive(:new).with(donor).and_return(are_you_ready_step)
    allow(Onboarding::WhatIsYourFirstName).to receive(:new).with(donor).and_return(first_name_step)
    allow(Onboarding::WhatIsYourEmail).to receive(:new).with(donor).and_return(email_step)
    allow(Onboarding::DidYouDonateLastYear).to receive(:new).with(donor).and_return(mock_step)
    allow(Onboarding::PrimaryReasons).to receive(:new).with(donor).and_return(mock_step)
    allow(Onboarding::HowDoYouDecideWhichOrganizationsToSupport).to receive(:new).with(donor).and_return(mock_step)
    allow(Onboarding::WhichCauseAreasMatterToYou).to receive(:new).with(donor).and_return(mock_step)
    allow(Onboarding::DiversityOfPortfolio).to receive(:new).with(donor).and_return(mock_step)
    allow(Onboarding::HowOftenWillYouContribute).to receive(:new).with(donor).and_return(mock_step)
    allow(Onboarding::DoYouKnowTheAverageContribution).to receive(:new).with(donor).and_return(mock_step)
    allow(Onboarding::HowMuchWillYouContribute).to receive(:new).with(donor).and_return(mock_step)
    allow(Onboarding::WhatIsYourPreTaxIncome).to receive(:new).with(donor).and_return(mock_step)

    # Mock step chaining
    allow(are_you_ready_step).to receive(:<<).and_return(first_name_step)
    allow(first_name_step).to receive(:<<).and_return(email_step)
    allow(email_step).to receive(:<<).and_return(mock_step)
    allow(mock_step).to receive(:<<).and_return(mock_step)

    # Mock Wizard creation
    allow(Wizard).to receive(:new).and_return(mock_wizard)

    # Mock NullStep
    allow(NullStep).to receive(:new).and_return(null_step)
    allow(null_step).to receive(:follow_up_messages).and_return([])
    allow(null_step).to receive(:error_messages).and_return([])
    allow(null_step).to receive(:messages).and_return([])
    allow(null_step).to receive(:heading).and_return('')

    # Mock channel methods that should not be called for most tests
    # These will be overridden in specific tests that need them to actually run

    # Mock broadcasting
    allow(OnboardingChannel).to receive(:broadcast_to)

    # Mock Rails logger
    allow(Rails.logger).to receive(:info)

    # Mock ApplicationController.renderer
    allow(ApplicationController).to receive(:renderer).and_return(double(render: '<html>rendered</html>'))

    # Mock Partners::GetPartnerForDonor
    partner_mock = double('Partner', currency: 'USD')
    allow(Partners::GetPartnerForDonor).to receive(:call).with(donor: donor).and_return(partner_mock)

    # Mock Money::Currency
    allow(Money::Currency).to receive(:new).with('USD').and_return(double('Currency'))

    # Mock Analytics::TrackEvent
    allow(Analytics::TrackEvent).to receive(:run)

    # Mock Rails routes
    url_helpers_mock = double('UrlHelpers', new_portfolio_path: '/portfolios/new')
    allow(Rails.application.routes).to receive(:url_helpers).and_return(url_helpers_mock)
  end

  describe '#subscribed' do
    it 'streams for the correct channel identifier' do
      expect(channel).to receive(:stream_for).with("#{donor.id}-#{room_id}")
      channel.subscribed
    end

    it 'creates a wizard with all onboarding steps' do
      expect(Wizard).to receive(:new).with(steps: anything)
      channel.subscribed
    end

    it 'initializes all required onboarding steps with the donor' do
      expect(Onboarding::AreYouReady).to receive(:new).with(donor)
      expect(Onboarding::WhatIsYourFirstName).to receive(:new).with(donor)
      expect(Onboarding::WhatIsYourEmail).to receive(:new).with(donor)
      expect(Onboarding::DidYouDonateLastYear).to receive(:new).with(donor)
      expect(Onboarding::PrimaryReasons).to receive(:new).with(donor)
      expect(Onboarding::HowDoYouDecideWhichOrganizationsToSupport).to receive(:new).with(donor)
      expect(Onboarding::WhichCauseAreasMatterToYou).to receive(:new).with(donor)
      expect(Onboarding::DiversityOfPortfolio).to receive(:new).with(donor)
      expect(Onboarding::HowOftenWillYouContribute).to receive(:new).with(donor)
      expect(Onboarding::DoYouKnowTheAverageContribution).to receive(:new).with(donor)
      expect(Onboarding::HowMuchWillYouContribute).to receive(:new).with(donor)
      expect(Onboarding::WhatIsYourPreTaxIncome).to receive(:new).with(donor)

      channel.subscribed
    end

    it 'chains all steps together using << operator' do
      expect(are_you_ready_step).to receive(:<<).with(first_name_step)
      expect(first_name_step).to receive(:<<).with(email_step)
      
      channel.subscribed
    end

    it 'stores the wizard in instance variable' do
      channel.subscribed
      expect(channel.instance_variable_get(:@wizard)).to eq(mock_wizard)
    end
  end

  describe '#unsubscribed' do
    before do
      channel.subscribed
    end

    it 'sets wizard to nil' do
      channel.unsubscribed
      expect(channel.instance_variable_get(:@wizard)).to be_nil
    end
  end

  describe '#start' do
    before do
      channel.subscribed
      allow(mock_wizard).to receive(:restart!)
      allow(mock_wizard).to receive(:current_step).and_return(mock_step)
      allow(channel).to receive(:broadcast_step)
    end

    it 'restarts the wizard' do
      expect(mock_wizard).to receive(:restart!)
      channel.start
    end

    it 'broadcasts the current step' do
      expect(channel).to receive(:broadcast_step).with(step: mock_step)
      channel.start
    end
  end

  describe '#respond' do
    let(:response_data) { { 'payload' => 'response=test_answer' } }
    let(:parsed_params) { { 'response' => 'test_answer' } }

    before do
      channel.subscribed
      allow(Rack::Utils).to receive(:parse_nested_query).with('response=test_answer').and_return(parsed_params)
      allow(mock_wizard).to receive(:current_step).and_return(mock_step)
      allow(mock_wizard).to receive(:previous_step).and_return(mock_previous_step)
      allow(mock_wizard).to receive(:process_step!)
      allow(mock_wizard).to receive(:finished?).and_return(false)
      allow(channel).to receive(:broadcast_step)
      allow(channel).to receive(:broadcast_completion)
    end

    it 'logs the processing information' do
      allow(mock_step).to receive(:class).and_return('MockStep')
      expect(Rails.logger).to receive(:info).with("Processing MockStep with #{response_data}")
      channel.respond(response_data)
    end

    it 'parses the nested query parameters' do
      expect(Rack::Utils).to receive(:parse_nested_query).with('response=test_answer').and_return(parsed_params)
      channel.respond(response_data)
    end

    it 'processes the step with response parameter' do
      expect(mock_wizard).to receive(:process_step!).with('test_answer')
      channel.respond(response_data)
    end

    context 'when wizard is not finished' do
      before do
        allow(mock_wizard).to receive(:finished?).and_return(false)
      end

      it 'broadcasts the current step with previous step' do
        expect(channel).to receive(:broadcast_step).with(
          step: mock_step, 
          previous_step: mock_previous_step
        )
        channel.respond(response_data)
      end

      it 'does not broadcast completion' do
        expect(channel).not_to receive(:broadcast_completion)
        channel.respond(response_data)
      end
    end

    context 'when wizard is finished' do
      before do
        allow(mock_wizard).to receive(:finished?).and_return(true)
      end

      it 'broadcasts completion' do
        expect(channel).to receive(:broadcast_completion)
        channel.respond(response_data)
      end

      it 'does not broadcast step' do
        expect(channel).not_to receive(:broadcast_step)
        channel.respond(response_data)
      end
    end
  end

  describe '#broadcast_completion (private)' do
    before do
      channel.subscribed
    end

    it 'broadcasts completion message with redirect path' do
      expect(OnboardingChannel).to receive(:broadcast_to).with(
        "#{donor.id}-#{room_id}",
        redirect_to: '/portfolios/new'
      )
      channel.send(:broadcast_completion)
    end

    it 'tracks analytics event for onboarding finished' do
      expect(Analytics::TrackEvent).to receive(:run).with(
        user_id: donor.id,
        event: 'Onboarding finished'
      )
      channel.send(:broadcast_completion)
    end
  end

  describe '#broadcast_step (private)' do
    let(:follow_up_messages) { [double('Message')] }
    let(:error_messages) { [double('Message')] }
    let(:step_messages) { [double('Message')] }
    let(:combined_messages) { follow_up_messages + error_messages + step_messages }

    before do
      channel.subscribed
      allow(mock_step).to receive(:error_messages).and_return(error_messages)
      allow(mock_step).to receive(:messages).and_return(step_messages)
      allow(mock_step).to receive(:heading).and_return('Test Heading')
      allow(mock_previous_step).to receive(:follow_up_messages).and_return(follow_up_messages)
      allow(channel).to receive(:render_responses).with(mock_step).and_return('<html>responses</html>')
      # Allow render_responses to handle any step including NullStep instances
      allow(channel).to receive(:render_responses).and_return('')
      allow(channel).to receive(:render_responses).with(mock_step).and_return('<html>responses</html>')
    end

    it 'broadcasts step data with combined messages' do
      expect(OnboardingChannel).to receive(:broadcast_to).with(
        "#{donor.id}-#{room_id}",
        {
          messages: combined_messages,
          heading: 'Test Heading',
          responses: '<html>responses</html>'
        }
      )
      
      channel.send(:broadcast_step, step: mock_step, previous_step: mock_previous_step)
    end

    it 'combines messages in correct order' do
      # follow_up_messages + error_messages + step_messages
      expect(OnboardingChannel).to receive(:broadcast_to) do |_channel_id, data|
        expect(data[:messages]).to eq(combined_messages)
      end
      
      channel.send(:broadcast_step, step: mock_step, previous_step: mock_previous_step)
    end

    context 'with default NullStep parameters' do
      it 'works with default NullStep instances' do
        expect(OnboardingChannel).to receive(:broadcast_to).with(
          "#{donor.id}-#{room_id}",
          {
            messages: [],
            heading: '',
            responses: ''
          }
        )
        
        channel.send(:broadcast_step)
      end
    end
  end

  describe '#render_responses (private)' do
    before do
      channel.subscribed
      allow(mock_step).to receive(:display_as).and_return('radio_buttons')
      allow(channel).to receive(:donor_currency).and_return(double('Currency'))
    end

    it 'returns empty string when step is nil' do
      result = channel.send(:render_responses, nil)
      expect(result).to eq('')
    end

    it 'renders the correct partial with step and currency' do
      expect(ApplicationController.renderer).to receive(:render).with(
        partial: "conversations/radio_buttons",
        locals: { step: mock_step, currency: anything }
      ).and_return('<html>rendered</html>')
      
      result = channel.send(:render_responses, mock_step)
      expect(result).to eq('<html>rendered</html>')
    end

    it 'passes the donor currency to the partial' do
      currency_mock = double('Currency')
      allow(channel).to receive(:donor_currency).and_return(currency_mock)
      
      expect(ApplicationController.renderer).to receive(:render).with(
        partial: "conversations/radio_buttons",
        locals: { step: mock_step, currency: currency_mock }
      )
      
      channel.send(:render_responses, mock_step)
    end
  end

  describe '#donor_currency (private)' do
    let(:partner_mock) { double('Partner', currency: 'CAD') }
    let(:currency_mock) { double('Currency') }

    before do
      channel.subscribed
      allow(Partners::GetPartnerForDonor).to receive(:call).with(donor: donor).and_return(partner_mock)
      allow(Money::Currency).to receive(:new).with('CAD').and_return(currency_mock)
    end

    it 'gets partner for current donor' do
      expect(Partners::GetPartnerForDonor).to receive(:call).with(donor: donor)
      channel.send(:donor_currency)
    end

    it 'creates Money::Currency with partner currency' do
      expect(Money::Currency).to receive(:new).with('CAD')
      channel.send(:donor_currency)
    end

    it 'returns the currency object' do
      result = channel.send(:donor_currency)
      expect(result).to eq(currency_mock)
    end
  end

  describe 'integration with wizard flow' do
    let(:step1) { double('Step1', class: 'Step1', heading: 'Step 1', messages: [], error_messages: [], follow_up_messages: []) }
    let(:step2) { double('Step2', class: 'Step2', heading: 'Step 2', messages: [], error_messages: [], follow_up_messages: []) }

    before do
      # Don't call channel.subscribed here, we'll set up the wizard manually
      # Allow real Wizard creation for this integration test
      allow(Wizard).to receive(:new).and_call_original
      real_wizard = Wizard.new(steps: step1)
      channel.instance_variable_set(:@wizard, real_wizard)
      
      allow(step1).to receive(:process!).with('answer1').and_return(true)
      allow(step1).to receive(:next_step).and_return(step2)
      allow(step2).to receive(:next_step).and_return(nil)
      allow(step2).to receive(:process!).and_return(true)
      allow(channel).to receive(:render_responses).and_return('<html>responses</html>')
    end

    it 'progresses through wizard steps correctly' do
      # Start wizard
      channel.start
      real_wizard = channel.instance_variable_get(:@wizard)
      expect(real_wizard.current_step).to eq(step1)

      # Process first step
      channel.respond({ 'payload' => 'response=answer1' })
      expect(real_wizard.current_step).to eq(step2)
      expect(real_wizard.previous_step).to eq(step1)
    end

    it 'handles wizard completion' do
      # Start and process to completion
      channel.start
      real_wizard = channel.instance_variable_get(:@wizard)
      allow(step2).to receive(:process!).and_return(true)
      
      # Process first step
      channel.respond({ 'payload' => 'response=answer1' })
      
      # Process final step (should finish wizard)
      expect(channel).to receive(:broadcast_completion)
      channel.respond({ 'payload' => 'response=final_answer' })
      
      expect(real_wizard.finished?).to be true
    end
  end

  describe 'error handling' do
    before do
      channel.subscribed
    end

    context 'when wizard processing fails' do
      before do
        allow(mock_wizard).to receive(:current_step).and_return(mock_step)
        allow(mock_wizard).to receive(:process_step!).and_raise(StandardError, 'Processing failed')
      end

      it 'allows errors to bubble up' do
        expect {
          channel.respond({ 'payload' => 'response=test' })
        }.to raise_error(StandardError, 'Processing failed')
      end
    end

    context 'when rendering fails' do
      before do
        allow(ApplicationController.renderer).to receive(:render).and_raise(StandardError, 'Render failed')
        allow(mock_step).to receive(:display_as).and_return('radio_buttons')
      end

      it 'allows render errors to bubble up' do
        expect {
          channel.send(:render_responses, mock_step)
        }.to raise_error(StandardError, 'Render failed')
      end
    end

    context 'when partner service fails' do
      before do
        allow(Partners::GetPartnerForDonor).to receive(:call).and_raise(StandardError, 'Partner service failed')
      end

      it 'allows partner service errors to bubble up' do
        expect {
          channel.send(:donor_currency)
        }.to raise_error(StandardError, 'Partner service failed')
      end
    end
  end

  describe 'channel inheritance' do
    it 'inherits from ApplicationCable::Channel' do
      expect(OnboardingChannel).to be < ApplicationCable::Channel
    end

    it 'has access to current_donor from connection' do
      expect(channel.current_donor).to eq(donor)
    end

    it 'has access to params from subscription' do
      expect(channel.params['room']).to eq(room_id)
    end
  end
end
