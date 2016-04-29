require 'sinatra'
require 'json'
require 'lifx'

# LIFX = 5439 on a phone
set :port, 5439
set :environment, :production

num_bulbs = ARGV[0].nil? ? 1 : ARGV[0].to_i

print "Looking for #{num_bulbs} bulb(s)\n"
print " ***  Wrong number? run again and specify correct number as first argument\n"

# find the bulbs
begin
  c = LIFX::Client.lan
  c.discover! do |i|
    c.lights.count == num_bulbs;
  end
rescue
  print " *** Failed to discover required bulbs (#{c.lights.count}/#{num_bulbs})"
  print " *** We'll continue on with what we found."
end

print "Found #{c.lights.count} bulb(s) to control\n"

# return number of bulbs
get '/bulbs' do
  return_message = {}
  return_message[:total] = c.lights.count
  return_message.to_json
end

# return current colour of first bulb
get '/colour' do
  return_message = {}
  lights = c.lights.to_a
  if lights[0].on?
    begin
      clr = lights[0].color(refresh: true)
      return_message[:h] = clr.hue
      return_message[:s] = clr.saturation
      return_message[:b] = clr.brightness
      return_message[:k] = clr.kelvin
    rescue LIFX::Light::MessageTimeout
      return_message[:status] = "lights timed out"
    end
  else
    return_message[:status] = "lights off"
  end
  return_message.to_json
end

# currently operates on all bulbs but will need to make them addressable
# eventually
post '/hsbk' do
  return_message = {}
  begin
    jdata = JSON.parse(params[:colour],:symbolize_names => true)
    if jdata.has_key?(:h) && jdata.has_key?(:s) && jdata.has_key?(:b) && jdata.has_key?(:k)
      colour = LIFX::Color.hsbk(jdata[:h], jdata[:s], jdata[:b], jdata[:k])
      if jdata.has_key?(:d)
        d = jdata[:d]
      else
        d = 5
      end
      if jdata[:b] == 0
        c.lights.set_color(colour, duration: 0).turn_off
      else
        c.lights.set_color(colour, duration: d).turn_on
      end
      return_message[:status] = 'ok'
    else
      return_message[:status] = 'incorrect arguments'
    end
  rescue TypeError
    return_message[:status] = 'invalid payload'
  rescue JSON::ParserError
    return_message[:status] = 'invalid json'
  end
  return_message.to_json
end

# Public URL, enforce slow changes and not too brite
post '/change' do
  return_message = {}
  begin
    jdata = JSON.parse(params[:colour],:symbolize_names => true)
    if jdata.has_key?(:hue)
      hue = jdata[:hue]
      sat = 1.0
      bri = 0.2
      if jdata[:hue] < 0
        bri = 0.0
      end
      if jdata[:hue] > 360
        sat = 0.0
      end
      colour = LIFX::Color.hsbk(hue, sat, bri, 3500)
      d = 3
      c.lights.set_color(colour, duration: d).turn_on
      return_message[:status] = 'ok'
    else
      return_message[:status] = 'incorrect arguments'
    end
  rescue TypeError
    return_message[:status] = 'invalid payload'
  rescue JSON::ParserError
    return_message[:status] = 'invalid json'
  end
  return_message.to_json
end

get '/*' do
  return_message = {}
  return_message[:status] = 'bad route'
  return_message.to_json
end

post '/*' do
  return_message = {}
  return_message[:status] = 'bad route'
  return_message.to_json
end

before do
  content_type 'application/json'
  headers 'Access-Control-Allow-Origin' => '*'
end
