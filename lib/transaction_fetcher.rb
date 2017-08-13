require 'omnistruct'
require 'yaml'
require 'json'
require 'rest-client'

class TransactionFetcher
  def initialize(access_token, account_id = nil)
    @access_token = access_token
    @account_id = account_id
  end

  def fetch(since: 2.weeks.ago)
    account_id = http_get('/accounts')['accounts'].first['id']
    transactions = http_get("/transactions?account_id=#{account_id}&since=#{since.strftime('%FT%TZ')}&expand[]=merchant")
    transactions['transactions'].map{|t| OmniStruct.new(t)}
  end

  def balance
    account_id = http_get('/accounts')['accounts'].first['id']
    (http_get("/balance?account_id=#{account_id}")['balance'].to_f / 100.0)
  end

  private

  def http_get(url)
    JSON.parse(RestClient.get("https://api.monzo.com#{url}", { 'Authorization' => "Bearer #{@access_token}" }))
  end
end
