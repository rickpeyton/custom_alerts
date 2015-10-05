module TwilioWrapper
  require 'twilio-ruby'
  SID = ENV['TWILIO_SID']
  TOKEN = ENV['TWILIO_TOKEN']
  NUMBERS = [ENV['TWILIO_RICK'], ENV['TWILIO_BECCA']]

  class Send
    def self.sms(message)
      @client = Twilio::REST::Client.new SID, TOKEN
      NUMBERS.each do |number|
        @client.account.messages.create({
          :from => ENV['TWILIO_NUMBER'],
          :to => number,
          :body => message,
        })
      end
    end
  end
end

