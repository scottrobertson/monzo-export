require 'omnistruct'
require 'yaml'
require 'json'
require 'rest-client'

class TransactionFetcher
  def initialize(access_token, current_account: false)
    @access_token = access_token
    @account_type = current_account ? "uk_retail" : "uk_prepaid"
    @account = http_get("/accounts?account_type=#{@account_type}")['accounts'].first
    @account_id = @account['id']
  end

  def fetch(since: 2.weeks.ago)
    transactions = http_get("/transactions?account_id=#{@account_id}&since=#{since.strftime('%FT%TZ')}&expand[]=merchant")
    transactions['transactions'].map{|t| OmniStruct.new(t)}
  end

  def balance
    (http_get("/balance?account_id=#{@account_id}")['balance'].to_f / 100.0)
  end

  def account_number
    @account['account_number']
  end

  def sort_code
    @account['sort_code']
  end

  def account_and_sort
    "#{sort_code} - #{account_number}"
  end

  private

  def http_get(url)
    JSON.parse(RestClient.get("https://api.monzo.com#{url}", { 'Authorization' => "Bearer #{@access_token}" }))
  end
end
