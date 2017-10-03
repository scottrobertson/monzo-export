require 'yaml'
require 'rest-client'

class OAuth

  def initialize()
    @redirectURI = 'http://localhost/monzotoqif/'
    @config = YAML.load_file('config.yml')
  end
  
  def getAccessToken()
	if !@config['access_token']
	  puts 'Authorization token not configured'
    end
	if Time.now > @config['expiry']
	  refreshToken(@config['clientId'], @config['clientSecret'], @config['refresh_token'])
	end
	@config['access_token']
  end
  
  def initialAuth(clientId, clientSecret)
    @config['clientId'] = clientId
	@config['clientSecret'] = clientSecret
	@config['state'] = SecureRandom.urlsafe_base64(64)
	saveConfig()
    say "Open the following URL in a browser:"
    say "https://auth.getmondo.co.uk/?client_id=#{clientId}&redirect_uri=#{@redirectURI}&response_type=code&state=#{@config['state']}"
  end
  
  def processAuthUrl(authCode, state)
    if state != @config['state']
	  say "Invalid callback state"
	 else
	   exchangeAuthCode(@config['clientId'], @config['clientSecret'], @redirectURI, authCode)
	   say "Access token retrieved"
	 end
  end
  
  def exchangeAuthCode(clientId, clientSecret, redirectURI, authCode)
	json = JSON.parse(RestClient.post("https://api.monzo.com/oauth2/token", {grant_type: 'authorization_code', client_id: @config['clientId'], client_secret: @config['clientSecret'], redirect_uri: @redirectURI, code: authCode}))
	@config['access_token'] = json['access_token']
	@config['refresh_token'] = json['refresh_token']
	@config['expiry'] = Time.now + json['expires_in'] - 120
	@config['state'] = ''
	saveConfig
  end
  
  def refreshToken(clientId, clientSecret, refreshToken)
	json = JSON.parse(RestClient.post("https://api.monzo.com/oauth2/token", {grant_type: 'refresh_token', client_id: @config['clientId'], client_secret: @config['clientSecret'], refresh_token: refreshToken}))
	@config['access_token'] = json['access_token']
	@config['refresh_token'] = json['refresh_token']
	@config['expiry'] = Time.now + json['expires_in']
	@config['state'] = ''
	saveConfig()
  end
  
  def saveConfig()
    File.write('config.yml', @config.to_yaml)
  end
end
