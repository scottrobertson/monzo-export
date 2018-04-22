#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'
require 'colorize'
require_relative 'lib/transaction_fetcher'
require_relative 'lib/qif_creator'
require_relative 'lib/csv_creator'
require_relative 'lib/oauth'

program :name, 'Monzo Export'
program :version, '0.0.1'
program :description, 'Create QIF files from your Monzo account'

command :qif do |c|
  c.syntax = 'monzo-export qif [options]'
  c.summary = 'Generate the QIF file'
  c.option '--access_token TOKEN', String, 'Your access token from: https://developers.monzo.com/'
  c.option '--since DATE', String, 'The date (YYYY-MM-DD) to start exporting transactions from. Defaults to 2 weeks ago'
  c.option '--folder PATH', String, 'The folder to export to. Defaults to ./exports'
  c.option '--settled_only', String, 'Only export settled transactions'
  c.option '--current_account', String, 'Export transactions from the current account instead of the prepaid account'
  c.option '--config_file FILE', String, 'Optional config filename'
  c.action do |args, options|
    since = options.since ? Date.parse(options.since).to_time : (Time.now - (60*60*24*14)).to_date
    config = options.config_file ? options.config_file : 'config.yml'
    access_token = options.access_token || OAuth.new(config).getAccessToken
    fetcher = TransactionFetcher.new(access_token, current_account: options.current_account)
    QifCreator.new(fetcher.fetch(since: since)).create(options.folder, settled_only: options.settled_only, account_number: (fetcher.account_number || 'prepaid'))

    if options.current_account
      say "Account Number: #{fetcher.account_number}"
      say "Sort Code: #{fetcher.sort_code}"
    end

    say "Balance: £#{fetcher.balance}"
  end
end

command :balance do |c|
  c.syntax = 'monzo-export balance [options]'
  c.summary = 'Show the balance'
  c.option '--access_token TOKEN', String, 'Your access token from: https://developers.monzo.com/'
  c.option '--current_account', String, 'Export transactions from the current account instead of the prepaid account'
  c.option '--config_file FILE', String, 'Optional config filename'
  c.action do |args, options|
    config = options.config_file ? options.config_file : 'config.yml'
    access_token = options.access_token || OAuth.new(config).getAccessToken
    fetcher = TransactionFetcher.new(access_token, current_account: options.current_account)

    if options.current_account
      say "Account Number: #{fetcher.account_number}"
      say "Sort Code: #{fetcher.sort_code}"
    end

    say "Balance: £#{fetcher.balance}"
  end
end

command :csv do |c|
  c.syntax = 'monzo-export csv [options]'
  c.summary = 'Generate the CSV file'
  c.option '--access_token TOKEN', String, 'Your access token from: https://developers.monzo.com/'
  c.option '--since DATE', String, 'The date (YYYY-MM-DD) to start exporting transactions from. Defaults to 2 weeks ago'
  c.option '--folder PATH', String, 'The folder to export to. Defaults to ./exports'
  c.option '--settled_only', String, 'Only export settled transactions'
  c.option '--current_account', String, 'Export transactions from the current account instead of the prepaid account'
  c.option '--config_file FILE', String, 'Optional config filename'
  c.action do |args, options|
    since = options.since ? Date.parse(options.since).to_time : (Time.now - (60*60*24*14)).to_date
    config = options.config_file ? options.config_file : 'config.yml'
    access_token = options.access_token || OAuth.new(config).getAccessToken
    fetcher = TransactionFetcher.new(access_token, current_account: options.current_account)
    CsvCreator.new(fetcher.fetch(since: since)).create(options.folder, settled_only: options.settled_only, account_number: (fetcher.account_number || 'prepaid'))
  end
end

command :authurl do |c|
  c.syntax = 'monzo-export auth_url [options]'
  c.summary = 'Configure OAuth for passwordless/tokenless login'
  c.option '--url URL', String, 'The authorization URL you received when you authorized Monzo Export from: https://developers.monzo.com/ you will need to enclose the URL in double quotes'
  c.option '--config_file FILE', String, 'Optional config filename'
  c.action do |args, options|
    config = options.config_file ? options.config_file : 'config.yml'
    if options.url
      urlParams = CGI.parse(URI.parse(options.url).query)

      unless urlParams['code'][0]
        say "Badly formatted URL. Missing the code parameter"
        abort
      end

      unless urlParams['state'][0]
        say "Badly formatted URL. Missing the state parameter"
        abort
      end

      auth = OAuth.new(config).processAuthUrl(urlParams['code'][0], urlParams['state'][0])
    else
      say "authcode is required"
    end
  end
end

command :auth do |c|
  c.syntax = 'monzo-export auth [options]'
  c.summary = 'Configure OAuth for passwordless/tokenless login'
  c.option '--clientid ID', String, 'Your confidential client ID from: https://developers.monzo.com/'
  c.option '--clientsecret ID', String, 'Your confidential client secret from: https://developers.monzo.com/'
  c.option '--config_file FILE', String, 'Optional config filename'
  c.action do |args, options|
    config = options.config_file ? options.config_file : 'config.yml'
    OAuth.new(config).initialAuth(options.clientid, options.clientsecret)
  end
end
