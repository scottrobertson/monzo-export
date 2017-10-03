#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'
require 'colorize'
require_relative 'lib/transaction_fetcher'
require_relative 'lib/qif_creator'
require_relative 'lib/oauth'

program :name, 'Monzo to QIF'
program :version, '0.0.1'
program :description, 'Create QIF files from your Monzo account'

command :generate do |c|
  c.syntax = 'Monzo to QIF generate [options]'
  c.summary = 'Generate the QIF file'
  c.description = ''
  c.option '--since DATE', String, 'The date (YYYY-MM-DD) to start exporting transactions from. Defaults to 2 weeks ago'
  c.option '--folder PATH', String, 'The folder to export to. Defaults to ./exports'
  c.option '--settled_only', String, 'Only export settled transactions'
  c.option '--current_account', String, 'Export transactions from the current account instead of the prepaid account'
  c.action do |args, options|
    since = options.since ? Date.parse(options.since).to_time : (Time.now - (60*60*24*14)).to_date
    auth = OAuth.new()
	fetcher = TransactionFetcher.new(auth.getAccessToken(), current_account: options.current_account)
    qif = QifCreator.new(fetcher.fetch(since: since)).create(options.folder, settled_only: options.settled_only, account_number: (fetcher.account_number || 'prepaid'))

    if options.current_account
      say "Account Number: #{fetcher.account_number}"
      say "Sort Code: #{fetcher.sort_code}"
    end

    say "Balance: £#{fetcher.balance}"
  end
end

command :auth do |c|
  c.syntax = 'Monzo to QIF auth [options]'
  c.summary = 'Configure OAuth for passwordless/tokenless login'
  c.description = 'This is a 2 step authorization process. Step 1 configures the client and requests an auth code from monzo. Step 2 exchanges the auth code for an auth and refresh token. First run Monzo to QIF auth --clientid ID --clientsecret ID and follow the instructions. Secondly paste the url from the login email as the argument to Monzo to QIF auth --authurl URL'
  c.option '--clientid ID', String, 'Your confidential client ID from: https://developers.monzo.com/'
  c.option '--clientsecret ID', String, 'Your confidential client secret from: https://developers.monzo.com/'
  c.option '--authurl URL', String, 'The authorization URL you received when you authorized Monzo to QIF from: https://developers.monzo.com/ you will need to escape the & character in the url'
  c.action do |args, options|
    if options.clientid && options.clientsecret
	  auth = OAuth.new().initialAuth(options.clientid, options.clientsecret)
	end
	if options.authurl
	  urlParams = CGI.parse(URI.parse(options.authurl).query)
	  auth = OAuth.new().processAuthUrl(urlParams['code'][0], urlParams['state'][0])
	end
  end
end