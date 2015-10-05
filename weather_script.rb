require './wunderground_wrapper'
require './twilio_wrapper'
require 'json'
require 'date'


# Features to Implement

# 1. Check if we should leave the windows open at night
#    Above 66. Below 83. No rain

class Windows
  def self.check
    results = WundergroundWrapper::TenDay.get("AL", "Calera")
    hourly_results = JSON.parse(results)["hourly_forecast"]
    @lower_temp_threshold = 67
    @upper_temp_threshold = 82
    @upper_precipitation_threshold = 39
    @upper_humidity_threshold = 79
    @time_check = DateTime.now.hour < 12 ? "day" : "night"
    counter = 0
    @continue = true

    while counter < 10 && @continue == true do
      @temp = hourly_results[counter + 1]["temp"]["english"].to_i
      @precipitation_chance = hourly_results[counter]["pop"].to_i
      @humidity = hourly_results[counter]["humidity"].to_i
      check_temp_and_precipitation
      if @continue == true
        counter += 1
      end
    end

    take_decisive_action
  end

  def self.take_decisive_action
    case
    when @continue == true && windows_are_closed
      update_window_status("OPEN")
      @action = "Open the windows!"
      send_message
    when @continue == true && windows_are_open
      @action = "Leave the windows open!"
      send_message
    when @continue == false && windows_are_open
      update_window_status("CLOSED")
      @action = "Close the windows!"
      send_message
    end
  end

  def self.send_message
    TwilioWrapper::Send.sms("#{@action} #{@reason} #{@time_check}.")
  end

  def self.check_temp_and_precipitation
    case
    when @temp < @lower_temp_threshold
      @reason = "It is going to be a cool"
      @continue = false
    when @temp > @upper_temp_threshold
      @reason = "It is going to be a hot"
      @continue = false
    when @precipitation_chance > @upper_precipitation_threshold
      @reason = "It is going to be a rainy"
      @continue = false
    when @humidity > @upper_humidity_threshold && @temp > (@upper_temp_threshold - 5)
      @reason = "It is going to be a humid"
      @continue = false
    else
      @continue = true
      @reason = "It is going to be a beautiful"
    end
  end

  def self.update_window_status(message)
    File.open "window_status.txt", "w+" do |f|
      f.write message
    end
  end

  def self.windows_are_open
    (File.read "window_status.txt") == "OPEN"
  end

  def self.windows_are_closed
    (File.read "window_status.txt") == "CLOSED"
  end
end

# 2. On Sunday night check if we should bring the plants in.
#    What is the low temperature threshold for the plants?
#    Should we then have another notification to put them out?
#    Store a flag for whether or not they are already outside?

class Trees
  def self.run_check
    results = WundergroundWrapper::TenDay.get("AL", "Calera")
    hourly_results = JSON.parse(results)["hourly_forecast"]
    @lower_temp_threshold = 45
    counter = 0
    @continue = true

    while counter < 168 && @continue == true do
      @temp = hourly_results[counter]["temp"]["english"].to_i
      check_temp
      if @continue == true
        counter += 1
      end
    end

    if @continue == false && trees_are_outside
      TwilioWrapper::Send.sms("Bring the trees in! It is going to be a cold week.")
      update_tree_status("INSIDE")
    elsif @continue == true && trees_are_inside
      TwilioWrapper::Send.sms("Put the trees outside! It is going to be a nice week.")
      update_tree_status("OUTSIDE")
    end
  end

  def self.update_tree_status(message)
    File.open "tree_status.txt", "w+" do |f|
      f.write message
    end
  end

  def self.trees_are_outside
    (File.read "tree_status.txt") == "OUTSIDE"
  end

  def self.trees_are_inside
    (File.read "tree_status.txt") == "INSIDE"
  end

  def self.check_temp
    case
    when @temp < @lower_temp_threshold
      @continue = false
    else
      @continue = true
    end
  end
end

# 3. If it is Tuesday, text to take out the garbage

class Garbage
  def self.send_reminder
    TwilioWrapper::Send.sms("It is garbage night!")
  end
end
