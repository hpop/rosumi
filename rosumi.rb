 require "uri"
 require 'json'
 require 'net/http'
 require 'net/https'
 require 'base64'

class Rosumi
  
  URL="fmipmobile.me.com"
  PORT=443
  
  attr_accessor :devices
  
  def initialize(user, pass)
    @user = user
    @pass = pass
    
    @devices = []

    @http = Net::HTTP.new(URL, PORT)
    @http.use_ssl=true

    self.updateDevices()
  end
  
  def updateDevices
    post = {'clientContext' => {'appName'       => 'FindMyiPhone',
                                'appVersion'    => '1.4',
                                'buildVersion'  => '57',
                                'deviceUDID'    => '0cf3dc989ff812adb0b202baed4f37274b210853',
                                'inactiveTime'  => 2147483647,
                                'osVersion'     => '4.2',
                                'productType'   => 'iPad1,1'
                                }};
    json_devices = self.post("/fmipservice/device/#{@user}/initClient", post)
    
    @devices = [];
    json_devices['content'].each { |json_device| @devices << json_device }
    
    @devices
    
  end
  
  def post(path, data)
		auth = Base64.encode64(@user+':'+@pass);
		puts auth;
		headers = {
		  'Authorization' => "Basic #{auth}",
      'User-Agent' => 'Find iPhone/1.2.1 MeKit (iPad: iPhone OS/4.2.1)',
      'X-Apple-Realm-Support' => '1.0',
      'Content-Type' => 'application/json; charset=utf-8',
      'X-Client-Name' => 'Steves iPad',
      'X-Client-Uuid' => '0cf3dc491ff812adb0b202baed4f94873b210853'
    }
    
    resp = fetch(path, JSON.generate(data), headers)
    
    return JSON.parse(resp.body);
  end

  def locate(device_num = 0, max_wait = 300)
    
    start = Time.now
    
    begin
      raise "Unable to find location within '#{max_wait}' seconds" if ((Time.now - start) > max_wait)

      sleep(5)
      self.updateDevices()
    end while (@devices[device_num]['location']['locationFinished'] == 'false') 

    loc = {
      :name      => @devices[device_num]['name'],
      :latitude  => @devices[device_num]['location']['latitude'],
      :longitude => @devices[device_num]['location']['longitude'],
      :accuracy  => @devices[device_num]['location']['horizontalAccuracy'],
      :timestamp => @devices[device_num]['location']['timeStamp'],
      :position_type  => @devices[device_num]['location']['positionType']
      };

    return loc;
  end

private 
  def fetch(path, data, headers, limit = 10)
    
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0

    response = @http.post(path, data, headers)
    case response
    when Net::HTTPSuccess     then response
    when Net::HTTPRedirection then fetch(response['location'], data, headers, limit - 1)
    else
      response.error!
    end
  end
  
end