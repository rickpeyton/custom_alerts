require './wunderground_wrapper'
require './twilio_wrapper'
require 'json'
require 'date'
require 'pry'


# Features to Implement

# 1. Check if we should leave the windows open at night
#    Above 66. Below 83. No rain

class Windows
  def self.check
    results = WundergroundWrapper::TenDay.get("AL", "Calera")
    @hourly_results = JSON.parse(results)["hourly_forecast"]
    @lower_temp_threshold = 67
    @upper_temp_threshold = 82
    @upper_precipitation_threshold = 39
    @upper_humidity_threshold = 79
    @time_check = DateTime.now.hour < 12 ? "day" : "night"
    @time_check == "day" ? day_check : night_check
    check_temp_and_precipitation
    take_decisive_action
  end

  def self.day_check
    day_results = @hourly_results.select { |x| (x["FCTTIME"]["hour"].to_i > 7 && x["FCTTIME"]["mday"].to_i == Date.today.day) && (x["FCTTIME"]["hour"].to_i < 18 && x["FCTTIME"]["mday"].to_i == Date.today.day) }
    narrowed_results = day_results.select do |x|
      x["pop"].to_i <= @upper_precipitation_threshold &&
      (x["humidity"].to_i < @upper_humidity_threshold &&
        x["temp"]["english"].to_i < @upper_temp_threshold - 5) &&
      x["temp"]["english"].to_i >= @lower_temp_threshold &&
      x["temp"]["english"].to_i <= @upper_temp_threshold
    end
    if narrowed_results.count >= 7
      start_time = narrowed_results.first["FCTTIME"]["hour"].to_i
      if start_time > 12
        start_time -= 12
      end
      @reason = "After #{start_time} it is going to be a beautiful"
    else
      check_results(day_results)
    end
  end

  def self.night_check
    night_results = @hourly_results.select { |x| (x["FCTTIME"]["hour"].to_i > 19 && x["FCTTIME"]["mday"].to_i == Date.today.day) || (x["FCTTIME"]["hour"].to_i < 6 && x["FCTTIME"]["mday"].to_i == (Date.today + 1).day) }

    check_results(night_results)
  end

  def self.check_results(results)
    if results.select { |x| x["pop"].to_i > @upper_precipitation_threshold }.count > 0
      @too_rainy = true
    end

    if results.select { |x| (x["humidity"].to_i > @upper_humidity_threshold) && (x["temp"]["english"].to_i > (@upper_temp_threshold - 5)) }.count > 0
      @too_humid = true
    end

    if results.select { |x| x["temp"]["english"].to_i < @lower_temp_threshold || x["temp"]["english"].to_i > @upper_temp_threshold }.count > 0
      @too_cold = true
    end

    if results.select { |x| x["temp"]["english"].to_i > @upper_temp_threshold }.count > 0
      @too_hot = true
    end
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
    when @too_rainy
      @reason = "It is going to be a rainy"
      @continue = false
    when @too_humid
      @reason = "It is going to be a humid"
      @continue = false
    when @too_hot
      @reason = "It is going to be a hot"
      @continue = false
    when @too_cold
      @reason = "It is going to be a cool"
      @continue = false
    when @reason
      @contine = true
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
