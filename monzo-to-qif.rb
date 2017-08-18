#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'
require 'colorize'
require_relative 'lib/transaction_fetcher'
require_relative 'lib/qif_creator'

program :name, 'Monzo to QIF'
program :version, '0.0.1'
program :description, 'Create QIF files from your Monzo account'

command :generate do |c|
  c.syntax = 'Monzo to QIF generate [options]'
  c.summary = 'Generate the QIF file'
  c.description = ''
  c.option '--access_token TOKEN', String, 'Your access token from: https://developers.monzo.com/'
  c.option '--since TOKEN', String, 'The date (YYYY-MM-DD) to start exporting transactions from. Defaults to nil'
  c.option '--folder PATH', String, 'The folder to export to. Defaults to ./exports'
  c.option '--settled_only', String, 'Only export settled transactions'
  c.option '--current_account', String, 'Export transactions from the current account instead of the prepaid account'
  c.action do |args, options|
    since = options.since ? Date.parse(options.since).to_time : nil
    if options.access_token
      fetcher = TransactionFetcher.new(options.access_token, current_account: options.current_account)
      qif = QifCreator.new(fetcher.fetch(since: since)).create(options.folder, settled_only: options.settled_only, account_number: (fetcher.account_number || 'prepaid'))

      say "Monzo Account: #{fetcher.account_and_sort}" if options.current_account
      say "Balance: £#{fetcher.balance}"
    else
      say 'Please supply an access_token'
    end
  end
end
