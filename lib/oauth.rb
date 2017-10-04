require 'yaml'
require 'rest-client'

class OAuth

  def initialize()
    @redirectURI = 'http://localhost/monzotoqif/'
    @config = YAML.load_file('config.yml')
  end
  
  def getAccessToken()
	if !@config['access_token']
	  say 'OAuth not configured. Please run Monzo to QIF auth'
	  abort
    end
	if Time.now > @config['expiry']
	  if @config['refresh_token']
	    refreshToken(@config['clientId'], @config['clientSecret'], @config['refresh_token'])
	  else
	    say 'Existing token has expired, please re-authenticate.'
	    initialAuth(@config['clientId'], @config['clientSecret'])
	  end
	end
	@config['access_token']
  end
  
  def initialAuth(clientId, clientSecret)
    @config['clientId'] = clientId
	@config['clientSecret'] = clientSecret
	@config['state'] = SecureRandom.urlsafe_base64(64)
	saveConfig()
    say "Open the following URL in a browser and follow the instructions. When you recieve the response email, copy the url and pass it to the --authurl parameter"
    say "https://auth.getmondo.co.uk/?client_id=#{clientId}&redirect_uri=#{@redirectURI}&response_type=code&state=#{@config['state']}"
  end
  
  def processAuthUrl(authCode, state)
    if state != @config['state']
	  say "Auth url state does not match internal state. Try setting up OAuth again."
	  abort
	 else
	   exchangeAuthCode(@config['clientId'], @config['clientSecret'], @redirectURI, authCode)
	 end
  end
  
  def exchangeAuthCode(clientId, clientSecret, redirectURI, authCode)
	json = JSON.parse(RestClient.post("https://api.monzo.com/oauth2/token", {grant_type: 'authorization_code', client_id: @config['clientId'], client_secret: @config['clientSecret'], redirect_uri: @redirectURI, code: authCode}))
	@config['access_token'] = json['access_token']
	# non-confidential clients won't return a refresh token
	if json['refresh_token']
      @config['refresh_token'] = json['refresh_token']
	end
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
