class App < Sinatra::Base
  def initialize
    super
    @lightwave = LightwaveRF.new
  end

  get "/" do
    body "Usage: turn items on or off: /[on|off]/:room/:device to dim /dim/:room/:device/:level. Level should be between 0 and 100."
  end

  get "/:room/:device/:action/?:level?" do |room, device, action, level|
    return [422, "Level required for dim"] if action == "dim" && !level
    case action
    when /on/i
      @lightwave.turn_on(room, device)
    when /off/i
      @lightwave.turn_off(room, device)
    when /dim/i
      puts level
      @lightwave.dim(room, device, level.to_i)
    else
      return [422, "Unknown action #{action}"]
    end
    body "Room #{room} Device #{device} #{action}#{" to #{level}%" if level}."
  end
end
