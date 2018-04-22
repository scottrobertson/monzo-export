require 'yaml'
require 'rest-client'

class OAuth
  def initialize(configFile)
    @configFile = configFile
    @redirectURI = 'http://localhost/monzo-export'
    @config = File.file?(@configFile) ? YAML.load_file(@configFile) : {}
  end

  def getAccessToken()
    unless @config['access_token']
      say 'OAuth not configured. Please run the following command'
      say 'ruby monzo-export.rb auth --clientid {clientID} --clientsecret {clientSecret}'
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
    if clientId.nil? || clientSecret.nil?
      say 'client_id and client_secret are required'
      return
    end

    @config['clientId'] = clientId
    @config['clientSecret'] = clientSecret
    @config['state'] = SecureRandom.hex

    saveConfig()

    say "Open the following URL in a browser and follow the instructions."
    puts ''
    say "https://auth.getmondo.co.uk/?client_id=#{clientId}&redirect_uri=#{@redirectURI}&response_type=code&state=#{@config['state']}"
    puts ''
    say "Once you receive the email, please copy the 'Login to Monzo' URL and run the following command"
    puts ''
    say 'ruby monzo-export.rb authurl --url #{link-from-email}'
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
    begin
      response = RestClient.post("https://api.monzo.com/oauth2/token", {
        grant_type: 'authorization_code',
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirectURI,
        code: authCode
      })

      json = JSON.parse(response)
    rescue => e
      raise e.response.to_yaml
    end

    @config['access_token'] = json['access_token']

    # non-confidential clients won't return a refresh token
    if json['refresh_token']
      @config['refresh_token'] = json['refresh_token']
    end

    @config['expiry'] = Time.now + json['expires_in'] - 120
    @config['state'] = nil

    saveConfig

    say 'Config Saved'
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
    File.write(@configFile, @config.to_yaml)
  end
end
