require 'omnistruct'
require 'yaml'
require 'json'
require 'rest-client'

class TransactionFetcher
  def initialize(access_token, account_id: nil)
    @access_token = access_token

    accounts =  http_get("/accounts")['accounts']

    if account_id.nil?
      @account = accounts.first
      @account_id = @account['id']
    else
      @account_id = account_id
      @account = accounts.find{|a| a['id'] == account_id }
    end
  end

  def fetch(since: (Time.now - (60*60*24*14)).to_date)
    transactions = http_get("/transactions?account_id=#{@account_id}&since=#{since.strftime('%FT%TZ')}&expand[]=merchant")
    # delete the fees children as they contain an unparsable key (withdrawal.atm.international)
    transactions['transactions'].each {|x| x.delete_if {|y| y == "fees"}}
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

  private

  def http_get(url)
    JSON.parse(RestClient.get("https://api.monzo.com#{url}", { 'Authorization' => "Bearer #{@access_token}" }))
  end
end
