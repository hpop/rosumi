 require "uri"
 require 'json'
 require 'net/http'
 require 'net/https'
 require 'base64'

class Rosumi
  
  URL="fmipmobile.icloud.com"
  PORT=443
  
  attr_accessor :devices
  
  def initialize(user, pass)
    @user = user
    @pass = pass
    
    @devices = []

    @partition = nil

    @http = Net::HTTP.new(URL, PORT)
    @http.use_ssl=true

    self.updateDevices()
  end
  
  

  def updateDevices
    post = {'clientContext' => {'appName'       => 'FindMyiPhone',
                                'appVersion'    => '1.4',
                                'buildVersion'  => '145',
                                'deviceUDID'    => '0000000000000000000000000000000000000000',
                                'inactiveTime'  => 2147483647,
                                'osVersion'     => '4.2.1',
                                'personID'      => 0,
                                'productType'   => 'iPad1,1'
                                }};
    
    json_devices = self.post("/fmipservice/device/#{@user}/initClient", post)
    puts 'posted'
    puts json_devices
    @devices = [];
    json_devices['content'].each { |json_device| @devices << json_device }
    
    @devices
    
  end
  
  def post(path, data)
		auth = Base64.encode64(@user+':'+@pass);
		puts auth;
		headers = {
      'Content-Type' => 'application/json; charset=utf-8',
      'X-Apple-Find-Api-Ver' => '2.0',
      'X-Apple-Authscheme' => 'UserIdGuest',
      'X-Apple-Realm-Support' => '1.2',
      'User-Agent' => 'Find iPhone/1.1 MeKit (iPad: iPhone OS/4.2.1)',
      'X-Client-Name' => 'iPad',
      'X-Client-Uuid' => '0cf3dc501ff812adb0b202baed4f37274b210853',
      'Accept-Language' => 'en-us',
      'Authorization' => "Basic #{auth}"
    }
    puts "Path = #{path}"   

    unless @partition
      @partition = fetchPartition(path, JSON.generate(data), headers) 
      @http = Net::HTTP.new(@partition, PORT)
      @http.use_ssl=true
    end

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
  
  def fetchPartition(path, data, headers)

    puts 'fetching partition'

    response = @http.post(path, data, headers)

    puts "got partition #{response['X-Apple-MMe-Host']}"
    
    response['X-Apple-MMe-Host']

  end

end