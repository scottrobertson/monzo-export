require 'omnistruct'
require 'json'
require 'rest-client'

class TransactionFetcher
  def initialize(access_token, account_id = nil)
    @access_token = access_token
    @account_id = account_id
  end

  def fetch(since: DEFAULT_DATE)
    since = since || DEFAULT_DATE
    account_id = http_get('/accounts')['accounts'].first['id']
    transactions = http_get("/transactions?account_id=#{account_id}&since=#{since.strftime('%FT%TZ')}&expand[]=merchant")
    transactions['transactions'].map{|t| OmniStruct.new(t)}
  end

  private
  TWO_WEEKS_SECONDS = 2 * 7 * 24 * 60 * 60
  DEFAULT_DATE = Time.now - TWO_WEEKS_SECONDS

  def http_get(url)
    JSON.parse(RestClient.get("https://api.monzo.com#{url}", { 'Authorization' => "Bearer #{@access_token}" }))
  end
end
