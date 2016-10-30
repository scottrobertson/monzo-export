require 'mondo'

class TransactionFetcher
  def initialize(access_token, account_id = nil)
    @access_token = access_token
    @account_id = account_id
  end

  def fetch(since: 2.weeks.ago)
    monzo_client.transactions(since: since.utc.strftime('%FT%TZ'), expand: [:merchant])
  end

  private

  def monzo_client
     @_monzo_client ||= Mondo::Client.new(
      token: @access_token,
      account_id: @account_id
    )
  end

end
