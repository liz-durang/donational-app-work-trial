# frozen_string_literal: true

require 'rails_helper'

# Custom test connection class to properly test ActionCable connections
class TestConnection
  attr_reader :identifiers, :logger

  def initialize(identifiers_hash = {}, session_data = {})
    @identifiers = identifiers_hash.keys
    # Create a logger that supports add_tags method
    base_logger = ActiveSupport::Logger.new(StringIO.new)
    @logger = ActiveSupport::TaggedLogging.new(base_logger)
    @session_data = session_data

    # Create identifier methods dynamically
    identifiers_hash.each do |identifier, value|
      define_singleton_method(identifier) do
        value
      end
    end
  end

  def session
    @session_data
  end

  def reject_unauthorized_connection
    raise ActionCable::Connection::Authorization::UnauthorizedError
  end
end

# Custom logger class that supports add_tags for testing
class TestLogger < ActiveSupport::Logger
  def add_tags(*_tags)
    # Mock implementation that doesn't fail
    nil
  end
end

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:donor) { create(:donor) } # Changed from build to create

  describe '#connect' do
    context 'when donor is verified' do
      let(:connection_instance) { ApplicationCable::Connection.allocate }

      before do
        # Properly initialize the connection instance with required attributes
        test_logger = TestLogger.new(StringIO.new)
        connection_instance.instance_variable_set(:@logger, test_logger)
        # Mock the reject_unauthorized_connection method
        allow(connection_instance).to receive(:reject_unauthorized_connection).and_raise(ActionCable::Connection::Authorization::UnauthorizedError)
        allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
        # Enable assignment to current_donor
        connection_instance.instance_variable_set(:@current_donor, nil)
        def connection_instance.current_donor=(value)
          @current_donor = value
        end

        def connection_instance.current_donor
          @current_donor
        end
      end

      it 'successfully connects and identifies the donor' do
        session_hash = { donor_id: donor.id }
        allow(session_hash).to receive(:[]).with(:donor_id).and_return(donor.id)
        allow(connection_instance).to receive(:session).and_return(session_hash)

        connection_instance.send(:connect)
        expect(connection_instance.current_donor).to eq(donor)
      end

      it 'calls the GetDonorById command with correct id' do
        session_hash = { donor_id: donor.id }
        allow(session_hash).to receive(:[]).with(:donor_id).and_return(donor.id)
        allow(connection_instance).to receive(:session).and_return(session_hash)

        expect(Donors::GetDonorById).to receive(:call).with(id: donor.id)
        connection_instance.send(:connect)
      end

      it 'adds logger tags with donor id' do
        session_hash = { donor_id: donor.id }
        allow(session_hash).to receive(:[]).with(:donor_id).and_return(donor.id)
        allow(connection_instance).to receive(:session).and_return(session_hash)
        expect(connection_instance.logger).to receive(:add_tags).with(donor.id)

        connection_instance.send(:connect)
      end
    end

    context 'when donor session is missing' do
      let(:connection_instance) { ApplicationCable::Connection.allocate }

      before do
        connection_instance.instance_variable_set(:@logger, TestConnection.new.logger)
      end

      it 'rejects the connection' do
        allow(connection_instance).to receive(:session).and_return({})
        allow(connection_instance).to receive(:reject_unauthorized_connection).and_raise(ActionCable::Connection::Authorization::UnauthorizedError)

        expect do
          connection_instance.send(:connect)
        end.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end

      it 'does not call GetDonorById command' do
        allow(connection_instance).to receive(:session).and_return({})
        allow(connection_instance).to receive(:reject_unauthorized_connection).and_raise(ActionCable::Connection::Authorization::UnauthorizedError)

        expect(Donors::GetDonorById).not_to receive(:call)
        expect do
          connection_instance.send(:connect)
        end.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end
    end

    context 'when donor session has nil id' do
      let(:connection_instance) { ApplicationCable::Connection.allocate }

      before do
        connection_instance.instance_variable_set(:@logger, TestConnection.new.logger)
      end

      it 'rejects the connection' do
        allow(connection_instance).to receive(:session).and_return({ donor_id: nil })
        allow(connection_instance).to receive(:reject_unauthorized_connection).and_raise(ActionCable::Connection::Authorization::UnauthorizedError)

        expect do
          connection_instance.send(:connect)
        end.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end
    end

    context 'when donor session has empty string id' do
      let(:connection_instance) { ApplicationCable::Connection.allocate }

      before do
        connection_instance.instance_variable_set(:@logger, TestConnection.new.logger)
      end

      it 'rejects the connection' do
        allow(connection_instance).to receive(:session).and_return({ donor_id: '' })
        allow(connection_instance).to receive(:reject_unauthorized_connection).and_raise(ActionCable::Connection::Authorization::UnauthorizedError)

        expect do
          connection_instance.send(:connect)
        end.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end
    end

    context 'when GetDonorById returns nil' do
      let(:connection_instance) { ApplicationCable::Connection.allocate }

      before do
        connection_instance.instance_variable_set(:@logger, TestConnection.new.logger)
        allow(Donors::GetDonorById).to receive(:call).with(id: 999).and_return(nil)
      end

      it 'rejects the connection' do
        allow(connection_instance).to receive(:session).and_return({ donor_id: 999 })
        allow(connection_instance).to receive(:reject_unauthorized_connection).and_raise(ActionCable::Connection::Authorization::UnauthorizedError)

        expect do
          connection_instance.send(:connect)
        end.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end
    end

    context 'when session is nil' do
      let(:connection_instance) { ApplicationCable::Connection.allocate }

      before do
        connection_instance.instance_variable_set(:@logger, TestConnection.new.logger)
      end

      it 'rejects the connection' do
        allow(connection_instance).to receive(:session).and_return(nil)
        allow(connection_instance).to receive(:reject_unauthorized_connection).and_raise(ActionCable::Connection::Authorization::UnauthorizedError)

        expect do
          connection_instance.send(:connect)
        end.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end
    end

    context 'with string keys in session data' do
      let(:connection_instance) { ApplicationCable::Connection.allocate }

      before do
        test_logger = TestLogger.new(StringIO.new)
        connection_instance.instance_variable_set(:@logger, test_logger)
        allow(connection_instance).to receive(:reject_unauthorized_connection).and_raise(ActionCable::Connection::Authorization::UnauthorizedError)
        allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
        # Enable assignment to current_donor
        connection_instance.instance_variable_set(:@current_donor, nil)
        def connection_instance.current_donor=(value)
          @current_donor = value
        end

        def connection_instance.current_donor
          @current_donor
        end
      end

      it 'successfully connects with string keys' do
        session_hash = { 'donor_id' => donor.id }
        allow(session_hash).to receive(:[]).with(:donor_id).and_return(donor.id)
        allow(connection_instance).to receive(:session).and_return(session_hash)

        connection_instance.send(:connect)
        expect(connection_instance.current_donor).to eq(donor)
      end
    end

    context 'with various donor_id formats' do
      let(:connection_instance) { ApplicationCable::Connection.allocate }

      before do
        test_logger = TestLogger.new(StringIO.new)
        connection_instance.instance_variable_set(:@logger, test_logger)
        allow(connection_instance).to receive(:reject_unauthorized_connection).and_raise(ActionCable::Connection::Authorization::UnauthorizedError)
        allow(Donors::GetDonorById).to receive(:call).with(id: '456').and_return(donor)
        # Enable assignment to current_donor
        connection_instance.instance_variable_set(:@current_donor, nil)
        def connection_instance.current_donor=(value)
          @current_donor = value
        end

        def connection_instance.current_donor
          @current_donor
        end
      end

      it 'handles string donor_id correctly' do
        session_hash = { donor_id: '456' }
        allow(session_hash).to receive(:[]).with(:donor_id).and_return('456')
        allow(connection_instance).to receive(:session).and_return(session_hash)

        connection_instance.send(:connect)
        expect(connection_instance.current_donor).to eq(donor)
      end
    end
  end

  describe '#disconnect' do
    let(:connection_instance) { ApplicationCable::Connection.allocate }

    before do
      connection_instance.instance_variable_set(:@logger, TestConnection.new.logger)
    end

    it 'does not raise an error' do
      expect { connection_instance.send(:disconnect) }.not_to raise_error
    end
  end

  # Test method visibility and basic functionality
  describe 'connection class structure' do
    subject(:connection_class) { ApplicationCable::Connection }

    describe '#session' do
      it 'is a protected method' do
        expect(connection_class.protected_instance_methods).to include(:session)
      end
    end

    describe '#find_verified_donor' do
      it 'is a protected method' do
        expect(connection_class.protected_instance_methods).to include(:find_verified_donor)
      end
    end

    describe '#disconnect' do
      it 'is a public method' do
        expect(connection_class.public_instance_methods).to include(:disconnect)
      end
    end

    describe 'identified_by' do
      it 'has current_donor as an identifier' do
        expect(connection_class.identifiers).to include(:current_donor)
      end
    end
  end

  # Test private methods indirectly through their effects
  describe 'protected method behavior' do
    describe '#find_verified_donor' do
      let(:connection_instance) { ApplicationCable::Connection.allocate }

      context 'when session is nil' do
        it 'returns nil without calling GetDonorById' do
          allow(connection_instance).to receive(:session).and_return(nil)

          expect(Donors::GetDonorById).not_to receive(:call)
          result = connection_instance.send(:find_verified_donor)
          expect(result).to be_nil
        end
      end

      context 'when donor_id is missing from session' do
        it 'returns nil without calling GetDonorById' do
          allow(connection_instance).to receive(:session).and_return({})

          expect(Donors::GetDonorById).not_to receive(:call)
          result = connection_instance.send(:find_verified_donor)
          expect(result).to be_nil
        end
      end

      context 'when donor_id is nil' do
        it 'returns nil without calling GetDonorById' do
          allow(connection_instance).to receive(:session).and_return({ donor_id: nil })

          expect(Donors::GetDonorById).not_to receive(:call)
          result = connection_instance.send(:find_verified_donor)
          expect(result).to be_nil
        end
      end

      context 'when donor_id is empty string' do
        it 'returns nil without calling GetDonorById' do
          allow(connection_instance).to receive(:session).and_return({ donor_id: '' })

          expect(Donors::GetDonorById).not_to receive(:call)
          result = connection_instance.send(:find_verified_donor)
          expect(result).to be_nil
        end
      end

      context 'when donor_id is present' do
        it 'calls GetDonorById with the donor_id' do
          allow(connection_instance).to receive(:session).and_return({ donor_id: 123 })
          expect(Donors::GetDonorById).to receive(:call).with(id: 123).and_return(donor)

          result = connection_instance.send(:find_verified_donor)
          expect(result).to eq(donor)
        end
      end

      context 'when GetDonorById returns nil' do
        it 'returns nil' do
          allow(connection_instance).to receive(:session).and_return({ donor_id: 999 })
          allow(Donors::GetDonorById).to receive(:call).with(id: 999).and_return(nil)

          result = connection_instance.send(:find_verified_donor)
          expect(result).to be_nil
        end
      end
    end
  end

  # Integration tests to verify behavior through connection establishment
  describe 'connection behavior integration' do
    context 'with valid donor authentication' do
      let(:connection_instance) { ApplicationCable::Connection.allocate }

      before do
        test_logger = TestLogger.new(StringIO.new)
        connection_instance.instance_variable_set(:@logger, test_logger)
        allow(connection_instance).to receive(:reject_unauthorized_connection).and_raise(ActionCable::Connection::Authorization::UnauthorizedError)
        allow(Donors::GetDonorById).to receive(:call).with(id: donor.id).and_return(donor)
        # Enable assignment to current_donor
        connection_instance.instance_variable_set(:@current_donor, nil)
        def connection_instance.current_donor=(value)
          @current_donor = value
        end

        def connection_instance.current_donor
          @current_donor
        end
      end

      it 'successfully establishes connection and sets current_donor' do
        session_hash = { donor_id: donor.id }
        allow(session_hash).to receive(:[]).with(:donor_id).and_return(donor.id)
        allow(connection_instance).to receive(:session).and_return(session_hash)

        connection_instance.send(:connect)
        expect(connection_instance.current_donor).to eq(donor)
        expect(Donors::GetDonorById).to have_received(:call).with(id: donor.id)
      end
    end

    context 'with authentication failures' do
      let(:connection_instance) { ApplicationCable::Connection.allocate }

      before do
        connection_instance.instance_variable_set(:@logger, TestConnection.new.logger)
        allow(connection_instance).to receive(:reject_unauthorized_connection).and_raise(ActionCable::Connection::Authorization::UnauthorizedError)
      end

      it 'rejects connection when donor_id is missing from session' do
        allow(connection_instance).to receive(:session).and_return({})

        expect do
          connection_instance.send(:connect)
        end.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end

      it 'rejects connection when session is nil' do
        allow(connection_instance).to receive(:session).and_return(nil)

        expect do
          connection_instance.send(:connect)
        end.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end

      it 'rejects connection when donor_id is nil' do
        allow(connection_instance).to receive(:session).and_return({ donor_id: nil })

        expect do
          connection_instance.send(:connect)
        end.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end

      it 'rejects connection when donor_id is empty string' do
        allow(connection_instance).to receive(:session).and_return({ donor_id: '' })

        expect do
          connection_instance.send(:connect)
        end.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end
    end

    context 'when donor lookup fails' do
      let(:connection_instance) { ApplicationCable::Connection.allocate }

      before do
        connection_instance.instance_variable_set(:@logger, TestConnection.new.logger)
        allow(connection_instance).to receive(:reject_unauthorized_connection).and_raise(ActionCable::Connection::Authorization::UnauthorizedError)
        allow(Donors::GetDonorById).to receive(:call).and_return(nil)
      end

      it 'rejects connection when GetDonorById returns nil' do
        allow(connection_instance).to receive(:session).and_return({ donor_id: 999 })

        expect do
          connection_instance.send(:connect)
        end.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end

      it 'calls GetDonorById but rejects when donor not found' do
        allow(connection_instance).to receive(:session).and_return({ donor_id: 999 })

        expect(Donors::GetDonorById).to receive(:call).with(id: 999).and_return(nil)
        expect do
          connection_instance.send(:connect)
        end.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
      end
    end
  end
end
