require 'JSON'
require 'pry'
require 'Requests'
require 'stringio'
require 'time'
require 'zlib'
require_relative '.secret/api_keys'

# Sample schema and response from MovesCount (added quotes etc. to be Ruby copy/paste-friendly):
# {Schema:{MoveID:{Index:0,Type:"int32"},StartTime:{Index:1,Type:"datetime"},ActivityID:{Index:2,Type:"int32"},Type:{Index:3,Type:"byte"},Duration:{Index:4,Type:"timespan"},Distance:{Index:5,Type:"int32"},HrAvg:{Index:6,Type:"int32"},HrZone:{Index:7,Type:"int32"},HrMin:{Index:8,Type:"int32"},HrMax:{Index:9,Type:"int32"},Feeling:{Index:10,Type:"int32"},TE:{Index:11,Type:"double"},Calories:{Index:12,Type:"int32"},SpeedAvg:{Index:13,Type:"double"},Ascent:{Index:14,Type:"double"},Descent:{Index:15,Type:"double"},SpeedMax:{Index:16,Type:"double"},DepthMax:{Index:17,Type:"double"},DepthAvg:{Index:18,Type:"double"},Visibility:{Index:19,Type:"single"},BottomTemperature:{Index:20,Type:"decimal"},TimeInZone1:{Index:21,Type:"double"},TimeInZone2:{Index:22,Type:"double"},TimeInZone3:{Index:23,Type:"double"},TimeInZone4:{Index:24,Type:"double"},TimeInZone5:{Index:25,Type:"double"},Notes:{Index:26,Type:"string"},Tags:{Index:27,Type:"string[]"},TempMin:{Index:28,Type:"double"},TempMax:{Index:29,Type:"double"},TempAvg:{Index:30,Type:"double"},CadenceMax:{Index:31,Type:"double"},CadenceAvg:{Index:32,Type:"double"},PowerMax:{Index:33,Type:"double"},PowerAvg:{Index:34,Type:"double"},AltitudeHigh:{Index:35,Type:"double"},AltitudeLow:{Index:36,Type:"double"},TimeAscent:{Index:37,Type:"timespan"},TimeDescent:{Index:38,Type:"timespan"},TimeFlat:{Index:39,Type:"timespan"},EpocPeak:{Index:40,Type:"double"},OxygenConsumptionMax:{Index:41,Type:"int32"},BreathingFrequencyMax:{Index:42,Type:"int32"},Latitude:{Index:43,Type:"decimal"},Longitude:{Index:44,Type:"decimal"},EMGAvg:{Index:45,Type:"int32"},EMGTotal:{Index:46,Type:"int32"},EMGLeft:{Index:47,Type:"double"},EMGFront:{Index:48,Type:"double"},Year:{Index:49,Type:"int32"},Month:{Index:50,Type:"int32"},Day:{Index:51,Type:"int32"}}}
# [[231064211,1532204103000.0,17,nil,374000,2800,nil,nil,nil,nil,nil,nil,89,7.48663,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,"Bike",nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,0,0,0,nil,nil,nil,nil,nil,nil,nil,nil,nil,2018,7,21],[231223198,1532253031000.0,17,nil,1271000,9768,nil,nil,nil,nil,nil,nil,309,7.68529,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,"Bike",nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,0,0,0,nil,nil,nil,nil,nil,nil,nil,nil,nil,2018,7,22],[231388490,1532325620000.0,17,nil,1274000,9720,nil,nil,nil,nil,nil,nil,305,7.62951,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,"Bike",nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,0,0,0,nil,nil,nil,nil,nil,nil,nil,nil,nil,2018,7,23],[231590821,1532412095000.0,17,nil,1272000,9945,nil,nil,nil,nil,nil,nil,322,7.8184,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,"Bike",nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,0,0,0,nil,nil,nil,nil,nil,nil,nil,nil,nil,2018,7,24],[232291511,1532717699000.0,17,nil,1271000,10235,nil,nil,nil,nil,nil,nil,345,8.05271,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,"Bike",nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,0,0,0,nil,nil,nil,nil,nil,nil,nil,nil,nil,2018,7,27],[232693598,1532867096000.0,17,nil,1934000,15385,nil,nil,nil,nil,nil,nil,507,7.95502,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,"Bike",nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,0,0,0,nil,nil,nil,nil,nil,nil,nil,nil,nil,2018,7,29],[232829320,1532932051000.0,17,nil,1934000,14999,nil,nil,nil,nil,nil,nil,483,7.75543,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,"Bike",nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,0,0,0,nil,nil,nil,nil,nil,nil,nil,nil,nil,2018,7,30],[233459266,1533192192000.0,17,nil,1930000,14902,nil,nil,nil,nil,nil,nil,479,7.72124,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,"Bike",nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,0,0,0,nil,nil,nil,nil,nil,nil,nil,nil,nil,2018,8,2],[233765391,1533326323000.0,17,nil,2590000,19859,nil,nil,nil,nil,nil,nil,633,7.66757,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,"Bike",nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,0,0,0,nil,nil,nil,nil,nil,nil,nil,nil,nil,2018,8,3]]

# Construct our URLs and fetch our data from Suunto.
def get_suunto_data
  suunto_url = 'http://www.movescount.com/Move/MoveList'
  suunto_query_params = {
    version: '1.1.0',
    clientUserId: '2319771',
  }
  cookie_header = "ASP.NET_SessionId=px0vjm3irhjfrbwaaz3hxiv4; Movescount_lang=9; MovesCountCookie=#{MOVESCOUNT_COOKIE};"
  suunto_headers = {
    'Cookie' => "#{cookie_header}",
    'Accept-Encoding' => 'gzip, deflate',
    'Accept-Language' => 'en-US,en;q=0.9,fr;q=0.8',
    'User-Agent' => 'https://github.com/ENuge/suunto2strava',
    'Accept' => 'application/json, text/javascript, */*',
    'q' => '0.01',
  }
  response = request_with_retries(suunto_url, suunto_query_params, suunto_headers)
end

# MovesCount gives us garbage ~30% of the time, so let's try up to 5 times.
def request_with_retries(url, query_params, headers, attempt_count=0)
  begin
    if attempt_count > 5
      raise Exception('Zlib::GzipFile::Error -> not in gzip format (malformed response)')
    end
    response = Requests.request("GET", url, params: query_params, headers: headers)
    response_string = Zlib::GzipReader.new(StringIO.new(response.body.to_s)).read
    JSON.parse(response_string)
  rescue Zlib::GzipFile::Error
    request_with_retries(url, query_params, headers, attempt_count+1)
  end
end

# Only keep activities newer than our last run
def get_recent_activities(schema, data)
  last_read_date = IO.readlines('./last_successful_run.txt')[0].strip()
  last_read_year, last_read_month, last_read_day = last_read_date.split('-').map(&:to_i)
  puts "Last successful run: #{last_read_date}"

  year_index = schema["Year"]["Index"]
  month_index = schema["Month"]["Index"]
  day_index = schema["Day"]["Index"]
  data.keep_if do |response_list|
    response_year = response_list[year_index]
    response_month = response_list[month_index]
    response_day = response_list[day_index]

    if response_year > last_read_year
      true
    elsif response_year == last_read_year && response_month > last_read_month
      true
    elsif response_year == last_read_year && response_month == last_read_month && response_day > last_read_day
      true
    else
      false
    end
  end
end

def post_to_strava(schema, recent_activities)
  strava_url = "https://www.strava.com/api/v3/activities"
  list_params = construct_strava_params_from_suunto(schema, recent_activities)
  strava_auth_header = {Authorization: "Bearer #{STRAVA_API_KEY}"}
  list_params.each do |params|
    response = Requests.request("POST", strava_url, params: params, headers: strava_auth_header)
  end
end

def construct_strava_params_from_suunto(schema, activities)
  # fields that Strava's API accepts
  start_time_index = schema["StartTime"]["Index"]
  # duration_index = suunto_response["Schema"]["Duration"]["Index"]
  duration_index = schema["Duration"]["Index"]
  distance_index = schema["Distance"]["Index"]
  list_params = []
  activities.each do |activity|
    params = {
      name: "Indoor Cycle",
      description: "Auto-imported from Suunto to Strava via suunto2strava",
      type: "Ride",
      private: 1,
    }
    params['start_date_local'] = Time.at((activity[start_time_index]/1000).to_i).iso8601
    params['elapsed_time'] = activity[duration_index]/1000
    params['distance'] = activity[distance_index]
    list_params << params
  end
  list_params
end

def main()
  response = get_suunto_data()
  schema = response["Schema"]
  data = response["Data"]

  recent_activities = get_recent_activities(schema, data)
  puts "Recent activities: #{recent_activities}"

  # === 
  # Now that we have recent_activities, format them in the way
  # Strava expects and POST 'em to their API
  # (https://developers.strava.com/playground/#/Activities/createActivity)
  # ===
  inserted_items = post_to_strava(schema, recent_activities)
  puts "Inserted the following into Strava: \n #{inserted_items}"

  # Then, update last_successful_run.txt with today's date.
  IO.write('./last_successful_run.txt', Time.now.strftime('%Y-%m-%d'))

  puts "================================="
  puts "= 🚀 All done! Happy cycling 🚲 ="
  puts "================================="
end

main()