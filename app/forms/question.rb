# A question in a conversational form
#
# Example:
#     class HowOldAreYou < Question
#       message 'Hi'
#       message 'What year were you born?'
#
#       display_as :integer
#
#       validates :response, numericality: { greater_than: 1900, less_than: Time.zone.now.year }
#
#       follow_up_message -> (response) do
#         if repsonse > 1980
#           "We <3 millenials!"
#         else
#           "#{response} was a good year!"
#         end
#       end
#
#       def save
#         Donors::UpdateDonor.run!(donor, year_of_birth: response)
#       end
#     end
class Question < Node
  attr_reader :response, :donor

  include ActiveModel::Model

  def initialize(donor)
    @donor = donor
  end

  # DSL method
  def self.message(m)
    @messages ||= []
    @messages << m
  end

  def self.messages
    @messages
  end

  def messages
    self.class.messages
  end

  def self.follow_up_message(proc_or_string)
    @follow_up_message = proc_or_string
  end

  def self.follow_up_message_for(response)
    return @follow_up_message.call(response) if @follow_up_message.respond_to?(:call)

    @follow_up_message
  end

  def follow_up_message
    self.class.follow_up_message_for(response)
  end

  def process!(raw_value)
    response_for_rollback = response
    self.response = raw_value

    if valid?
      save
    else
      @response = response_for_rollback
    end
  end

  def self.display_as(type)
    define_method :display_as do
      type
    end
  end

  def response=(raw_value)
    @response = case display_as
                when :integer
                  raw_value.to_i
                when :slider
                  raw_value.to_d
                when :currency
                  (raw_value.gsub(/[^0-9\.-]/, '').to_d * 100).to_i
                when :radio_buttons
                  raw_value.to_s.to_sym
                when :checkboxes
                  raw_value.map(&:to_sym)
                when :string
                  raw_value.to_s
                else
                  raw_value
                end
  end
end
