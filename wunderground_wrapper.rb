module WundergroundWrapper
  require "pry"
  require "net/http"
  API = ENV['WUNDERGROUND_API']

  class TenDay
    def self.get(state, city)
      begin
        uri = URI("http://api.wunderground.com/api/#{API}/hourly10day/q/#{state}/#{city}.json")

        # Create client
        http = Net::HTTP.new(uri.host, uri.port)

        # Create Request
        req =  Net::HTTP::Get.new(uri)
        # Add headers
        req.add_field "Cookie", "DT=1443451108:12081:365-dell-c6"

        # Fetch Request
        res = http.request(req)
        # puts "Response HTTP Status Code: #{res.code}"
        # puts "Response HTTP Response Body: #{res.body}"
        res.body
      rescue StandardError => e
        # puts "HTTP Request failed (#{e.message})"
        e.message
      end
    end
  end
end
