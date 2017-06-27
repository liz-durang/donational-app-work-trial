module Questions
  class ErrorStep < Question
    def follow_up_message
      "We had a little trouble understanding you. Let's try again."
    end

    def save(response)
      raise 'Cannot save an error step'
    end
  end
end
