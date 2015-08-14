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
  raise "Failed to discover required bulbs (#{c.lights.count}/#{num bulbs})"
end

print "Found #{c.lights.count} bulb(s) to control\n"

# return list of bulbs
get '/bulbs' do
  return_message = {}
  return_message[:status] = 'unfinished'
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
